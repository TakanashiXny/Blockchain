package data;

import config.MiniChainConfig;
import network.NetWork;
import spv.Proof;
import spv.SpvPeer;
import utils.MinerUtil;
import utils.SHA256Util;
import utils.SecurityUtil;

import java.security.PublicKey;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class MinerPeer extends Thread{

    private final BlockChain blockChain;
    private final NetWork netWork;

    public MinerPeer(BlockChain blockChain, NetWork netWork) {
        this.blockChain = blockChain;
        this.netWork = netWork;
    }

    @Override
    public void run() {
        while (true) {
            // 锁住网络中的交易池
            synchronized (netWork.getTransactionPool()) {
                TransactionPool transactionPool = netWork.getTransactionPool();

                while (!transactionPool.isFull()) {
                    try {
                        transactionPool.wait();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }

                // 从交易池中获取一批次的交易
                Transaction[] transactions = transactionPool.getAll();

                // 对该交易的签名进行验签，验证失败则退出
                if (!check(transactions)) {
                    System.out.println("transaction error!");
                    System.exit(-1);
                }

                // 以交易为参数，调用getBlockBody方法
                BlockBody blockBody = getBlockBody(transactions);
                // 以blockBody为参数，调用mine方法
                Block block = mine(blockBody);

                // 将挖出的block广播到网络
                boardcast(block);

                // 输出所有账户的余额总数
                System.out.println("the sum of all account amount: " + blockChain.getAllAccountAmount());
                transactionPool.notify();
            }
        }
    }

    public Proof getProof(String proofTxHash) {

        Block proofBlock = null;
        int proofHeight = -1;

        // 遍历链上所有区块内的所有交易，计算其哈希值，找出要验证哈希值的交易所在的区块
        for (Block block : blockChain.getBlocks()) {
            proofHeight++; // 获得区块高度（我们这里从0开始索引）
            for (Transaction transaction: block.getBlockBody().getTransactions()) {
                String txHash = SecurityUtil.sha256Digest(transaction.toString());
                if (txHash.equals(proofTxHash)) {
                    proofBlock = block;
                    break;
                }
            }
            if (proofBlock != null) {
                break;
            }
        }

        // 如果没找到该哈希的交易，则返回null
        if (proofBlock == null) {
            return null;
        }

        // 重新计算merkle树获得路径哈希值，同时记录相关的节点偏向信息，构建验证路径节点
        List<Proof.Node> proofPath = new ArrayList<>();
        List<String> list = new ArrayList<>();
        String pathHash = proofTxHash; // 路径哈希，即验证节点一路延伸至根节点的哈希值
        for (Transaction transaction : proofBlock.getBlockBody().getTransactions()) {
            String txHash = SecurityUtil.sha256Digest(transaction.toString());
            list.add(txHash);
        }
        // list大小为1时停止迭代
        while (list.size() != 1) {
            List<String> newList = new ArrayList<>();
            for (int i = 0; i < list.size(); i += 2) {
                String leftHash = list.get(i);
                // 如果出现奇数个结点，即最后一个节点没有右结点与其构成一对，就将当前节点复制一份作为右节点
                String rightHash = (i + 1 < list.size() ? list.get(i + 1) : leftHash);
                String parentHash = SecurityUtil.sha256Digest(leftHash + rightHash);
                newList.add(parentHash);

                // 如果某一个哈希值与路径哈希相同，则将另一个作为验证路径中的节点加入，同时记录偏向，并更新路径哈希
                if (pathHash.equals(leftHash)) {
                    Proof.Node proofNode = new Proof.Node(rightHash, Proof.Orientation.RIGHT);
                    proofPath.add(proofNode);
                    pathHash = parentHash;
                } else if (pathHash.equals(rightHash)) {
                    Proof.Node proofNode = new Proof.Node(leftHash, Proof.Orientation.LEFT);
                    proofPath.add(proofNode);
                    pathHash = parentHash;
                }

            }
            // 切换list，进行下一轮的计算
            list = newList;

        }
        String proofMerkleRootHash = list.get(0);

        // 构造Proof并返回
        return new Proof(proofTxHash, proofMerkleRootHash, proofHeight, proofPath);
    }

    /**
     * 广播区块到网络，这里广播区块头到spv节点
     * @param block
     */
    public void boardcast(Block block) {
        // 每个spv节点接受区块头
        SpvPeer spvPeer = netWork.getSpvPeer();
        spvPeer.accept(block.getBlockHeader());
    }

    /**
     * 矿工检查每笔交易是否正确，是否被篡改
     * @param transactions
     * @return
     */
    private boolean check(Transaction[] transactions) {
        for (int i = 0; i < transactions.length; i++) {
            Transaction transaction = transactions[i];
            // 签名的数据是该交易的inUtxos和outUtxos
            byte[] data = SecurityUtil.utxos2Bytes(transaction.getInUtxos(), transaction.getOutUtxos());
            byte[] sign = transaction.getSendSign();
            PublicKey publicKey = transaction.getSendPublicKey();
            if (!SecurityUtil.verify(data, sign, publicKey)) {
                return false;
            }
        }
        return true;
    }

    /**
     * 该方法根据传入的参数中的交易，构造并返回一个相应的区块体对象
     *
     * 查看BlockBody类中的字段以及构造方法你会发现，还需要根据这些交易计算Merkle树的根哈希值
     *
     * @param transactions 一批次的交易
     *
     * @return 根据参数中的交易构造出的区块体
     */
    public BlockBody getBlockBody(Transaction[] transactions) {
        assert transactions != null && transactions.length == MiniChainConfig.MAX_TRANSACTION_COUNT;
        //todo
        List<String> list = new ArrayList<>();
        for (Transaction transaction : transactions) {
            String txHash = SecurityUtil.sha256Digest(transaction.toString());
            list.add(txHash);
        }
        // list大小为1时停止迭代
        while (list.size() != 1) {
            List<String> newList = new ArrayList<>();
            for (int i = 0; i < list.size(); i += 2) {
                String leftHash = list.get(i);
                // 如果出现奇数个节点，即最后一个节点没有右节点与其构成一对，就将当前节点复制一份作为右节点
                String rightHash = (i + 1 < list.size() ? list.get(i + 1) : leftHash);
                String parentHash = SecurityUtil.sha256Digest(leftHash + rightHash);
                newList.add(parentHash);
            }
            // 切换list，进行下一轮的计算
            list = newList;
        }

        BlockBody blockBody = new BlockBody(list.get(0), transactions);
        return blockBody;
    }

    /**
     * 该方法即在循环中完成"挖矿"操作，其实就是通过不断的变换区块中的nonce字段，直至区块的哈希值满足难度条件，
     * 即可将该区块加入区块链中
     *
     * @param blockBody 区块体
     */
    private Block mine(BlockBody blockBody) {
        Block block = getBlock(blockBody);
        while (true) {
            String blockHash = SHA256Util.sha256Digest(block.toString());
            if (blockHash.startsWith(MinerUtil.hashPrefixTarget())) {
                System.out.println("Mined a new Block! Detail of the new Block : ");
                System.out.println(block.toString());
                System.out.println("And the hash of this Block is : " + SHA256Util.sha256Digest(block.toString()) +
                        ", you will see the hash value in next Block's preBlockHash field.");
                System.out.println();
                blockChain.addNewBlock(block);
                break;
            } else {
                //todo
                block = getBlock(blockBody);
            }
        }
        return block;
    }

    /**
     * 该方法供mine方法调用，其功能为根据传入的区块体参数，构造一个区块对象返回，
     * 也就是说，你需要构造一个区块头对象，然后用一个区块对象组合区块头和区块体
     *
     * 建议查看BlockHeader类中的字段和注释，有助于你实现该方法
     *
     * @param blockBody 区块体
     *
     * @return 相应的区块对象
     */
    public Block getBlock(BlockBody blockBody) {
        //todo
        Block preBlock = this.blockChain.getNewestBlock();  // 得到前一个块
        String preHash = SHA256Util.sha256Digest(preBlock.toString());

        Random random = new Random();

        // 生成随机的long整数
        long nonce = random.nextLong();

        BlockHeader blockHeader = new BlockHeader(preHash, blockBody.getMerkleRootHash(), nonce);

        Block ret = new Block(blockHeader, blockBody);
        return ret;
    }
}

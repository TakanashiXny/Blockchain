package network;

import config.MiniChainConfig;
import consensus.MinerNode;
import consensus.TransactionProducer;
import data.*;
import spv.SpvPeer;
import utils.SecurityUtil;

import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * 该类模拟一个网络环境，在该网络中主要有区块链和矿工，另外地，出于工程实现的角度，还有一个交易池和一个生成随机交易的线程
 *
 */
public class NetWork {

    private final Account[] accounts;
    private final SpvPeer[] spvPeers;
    private TransactionPool transactionPool;
    private TransactionProducer transactionProducer;
    private final BlockChain blockChain;
    private MinerPeer minerPeer;


    /**
     * 系统中几个主要成员的初始化
     */
    public NetWork() {

        // 初始化用户和spv节点，并注册到网络中
        System.out.println("\naccounts and spvPeers config");
        accounts = new Account[MiniChainConfig.ACCOUNT_NUM];
        spvPeers = new SpvPeer[MiniChainConfig.ACCOUNT_NUM];
        for (int i = 0; i < MiniChainConfig.ACCOUNT_NUM; i++) {
            accounts[i] = new Account();
            System.out.println("network register new account: " + accounts[i]);
            // 每个账户创建一个spv轻节点，并获得与网络的连接
            spvPeers[i] = new SpvPeer(accounts[i], this);
        }

        // 创建交易池，网络中会有交易涌入
        System.out.println("\ntransactionPool config...");
        transactionPool = new TransactionPool(MiniChainConfig.MAX_TRANSACTION_COUNT);

        // 交易产生着，负责生产交易，维持与网络的连接
        System.out.println("\ntransactionProducer config...");
        transactionProducer = new TransactionProducer(this);

        // 初始化一条区块链，后续由矿工节点维护，可当作这条链在网络中存储与矿工节点
        System.out.println("\nblockChain config...");
        blockChain = new BlockChain();

        // 创建矿工节点，维持与网络的连接
        System.out.println("\nminerPeer config...");
        minerPeer = new MinerPeer(blockChain, this);

        System.out.println("\nnetwork start!\n");

        // 将创世区块广播出去
        minerPeer.boardcast(blockChain.getNewestBlock());

        // 发送神秘大礼：在第一个区块放入一些utxo，让所有账户拥有一笔金额
        theyHavaADayDream();
    }

    public SpvPeer[] getSpvPeers() {
        return spvPeers;
    }

    /**
     * 让人富有的神秘函数
     */
    private void theyHavaADayDream() {
        // 在创世区块中为每一个账户分配一定金额的utxo，便于后面交易的进行
        UTXO[] outUtxos = new UTXO[accounts.length];
        for (int i = 0; i < accounts.length; i++) {
            outUtxos[i] = new UTXO(accounts[i].getWalletAddress(), MiniChainConfig.INIT_AMOUNT, accounts[i].getPublicKey());
        }
        // 神秘的公私钥
        KeyPair dayDreamKeyPair = SecurityUtil.secp256k1Generate();
        PublicKey dayDreamPublicKey = dayDreamKeyPair.getPublic();
        PrivateKey dayDreamPrivateKey = dayDreamKeyPair.getPrivate();
        // 神秘的签名内容
        byte[] sign = SecurityUtil.signature("Everything in the dream".getBytes(StandardCharsets.UTF_8), dayDreamPrivateKey);
        // 构造交易
        Transaction transaction = new Transaction(new UTXO[]{}, outUtxos, sign, dayDreamPublicKey, System.currentTimeMillis());
        // 交易数组只有这一个交易
        Transaction[] transactions = {transaction};
        // 前一个区块的哈希
        String preBlockHash = SecurityUtil.sha256Digest(blockChain.getNewestBlock().toString());
        // 因为本区块只有一个交易，所以merkle根哈希即为该交易的哈希
        String merkleRootHash = SecurityUtil.sha256Digest(transaction.toString());
        // 构建区块
        BlockHeader blockHeader = new BlockHeader(preBlockHash, merkleRootHash, Math.abs(new Random().nextLong()));
        BlockBody blockBody = new BlockBody(merkleRootHash, transactions);
        Block block = new Block(blockHeader, blockBody);
        // 添加到链中
        blockChain.addNewBlock(block);

        // 通过网络获取矿工结点，然后将初始区块广播出去
        minerPeer.boardcast(block);
    }


    /**
     * 启动挖矿线程和生成随机交易的线程
     */
    public void start() {
        transactionProducer.start();
        minerPeer.start();
    }

    public TransactionPool getTransactionPool() {
        return this.transactionPool;
    }

    public Account[] getAccounts() {
        return this.accounts;
    }

    public BlockChain getBlockChain() {
        return this.blockChain;
    }

    public MinerPeer getMinerPeer() {
        return this.minerPeer;
    }

    /**
     * 在最新区块中查找和某钱包地址有关的交易
     * @param walletAddress
     * @return
     */
    public List<Transaction> getTransactionsInLatestBlock(String walletAddress) {
        List<Transaction> list = new ArrayList<>();
        Block block = blockChain.getNewestBlock();
        // 遍历所有区块所有交易所有的UTXO，查看钱包地址是否相符合
        for (Transaction transaction : block.getBlockBody().getTransactions()) {
            boolean have = false;
            for (UTXO utxo : transaction.getInUtxos()) {
                if (utxo.getWalletAddress().equals(walletAddress)) {
                    list.add(transaction);
                    have = true;
                    break;
                }
            }
            if (have) {
                continue;
            }
            for (UTXO utxo : transaction.getOutUtxos()) {
                if (utxo.getWalletAddress().equals(walletAddress)) {
                    list.add(transaction);
                    break;
                }
            }
        }
        return list;
    }
}

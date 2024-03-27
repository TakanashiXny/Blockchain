package unit;

import config.MiniChainConfig;
import consensus.MinerNode;
import consensus.TransactionProducer;
import data.*;
import network.NetWork;
import org.junit.Before;
import org.junit.Test;
import utils.SecurityUtil;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class UtxoTest {
    private TransactionPool transactionPool;
    private BlockChain blockChain;
    private TransactionProducer transactionProducer;
    private NetWork netWork;

    @Test
    public void transactionTest() {
        transactionPool = new TransactionPool(MiniChainConfig.MAX_TRANSACTION_COUNT);
        NetWork netWork = new NetWork();
        blockChain = new BlockChain(netWork);

        transactionProducer = new TransactionProducer(netWork);
        MinerNode minerNode = new MinerNode(transactionPool, blockChain);

        Transaction transaction = getOneTransaction();
        transactionPool.put(transaction);
        minerNode.run();
    }

    private Transaction getOneTransaction() {
        Transaction transaction = null; // 返回的交易
        List<Account> accounts = netWork.getAccounts(); // 获取账户数组

        while (true) {
            Account aAccount = accounts.get(0);
            Account bAccount = accounts.get(1);

            // 获得钱包地址
            String aWalletAddress = aAccount.getWalletAddress();
            String bWalletAddress = bAccount.getWalletAddress();

            // 获取A可用的Utxo并计算余额
            UTXO[] aTrueUtxos = blockChain.getTrueUtxos(aWalletAddress);
            int aAmount = aAccount.getAmount(aTrueUtxos);
            // 如果A账户的余额为0，则无法构建交易，重新随机生成

            // 随机生成交易数额 [1, aAmount]之间
            int txAmount = 10000;
            // 构建InUtxos和OutUtxo
            List<UTXO> inUtxoList = new ArrayList<>();
            List<UTXO> outUtxoList = new ArrayList<>();

            // A账户需先解锁才能使用自己的utxo，解锁需要私钥签名和公钥才执行脚本，这里先生成需要解锁的签名
            // 签名的数据我们约定为公钥的二进制数据
            byte[] aUnlockSign = SecurityUtil.signature(aAccount.getPublicKey().getEncoded(), aAccount.getPrivateKey());

            // 选择输入总额>=交易数额的utxo
            int inAmount = 0;
            for (UTXO utxo : aTrueUtxos) {
                // 解锁成功才能使用该utxo
                if (utxo.unlockScript(aUnlockSign, aAccount.getPublicKey())) {
                    inAmount += utxo.getAmount();
                    inUtxoList.add(utxo);
                    if (inAmount >= txAmount) {
                        break;
                    }
                }
            }
            // 可解锁的utxo总额仍不足以支付交易数额，则重新随机
            if (inAmount < txAmount) {
                continue;
            }

            // 构建输出OutUtxos，A账户向B账户支付txAmount，同时输入对方的公钥以供生成公钥哈希
            outUtxoList.add(new UTXO(bWalletAddress, txAmount, bAccount.getPublicKey()));
            // 如果有余额，则“找零”，即给自己的utxo
            if (inAmount > txAmount) {
                outUtxoList.add(new UTXO(aWalletAddress, inAmount-txAmount, aAccount.getPublicKey()));
            }

            // 导出固定utxo数组
            UTXO[] inUtxos = inUtxoList.toArray(new UTXO[0]);
            UTXO[] outUtxos = outUtxoList.toArray(new UTXO[0]);

            // A账户需对整个交易进行私钥签名，确保交易不会被篡改，因为交易会传输到网络中，而上述步骤可在本地离线环境中构造
            // 获取要签名的数据，这个数据需要囊括交易信息
            byte[] data = SecurityUtil.utxos2Bytes(inUtxos, outUtxos);
            // A账户使用私钥签名
            byte[] sign = SecurityUtil.signature(data, aAccount.getPrivateKey());
            // 交易时间戳
            long timestamp = System.currentTimeMillis();
            // 构造交易
            transaction = new Transaction(inUtxos, outUtxos, sign, aAccount.getPublicKey(), timestamp);
            break;
        }
        return transaction;
    }

}

package data;

import network.NetWork;

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
            }
        }
    }
}

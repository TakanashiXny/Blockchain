package spv;

import java.util.List;

public class Proof {

    /**
     * 枚举类，哈希在merkle树中作为子节点的偏向：左节点或右节点
     */
    public enum Orientation {
        LEFT, RIGHT;
    }

    /**
     * 验证路径上的节点
     */
    public static class Node {
        private final String txHash;
        private final Orientation orientation;

        public Node(String txHash, Orientation orientation) {
            this.txHash = txHash;
            this.orientation = orientation;
        }

        public String getTxHash() {
            return txHash;
        }

        public Orientation getOrientation() {
            return orientation;
        }
    }

    // 待验证交易的交易哈希
    private final String txHash;
    // merkle树根哈希
    private final String merkleRootHash;
    // 待验证交易所在区块的高度
    private final int height;
    // 验证路径，内部的哈希值及其偏向
    private final List<Node> path;

    public Proof(String txHash, String merkleRootHash, int height, List<Node> path) {
        this.txHash = txHash;
        this.merkleRootHash = merkleRootHash;
        this.height = height;
        this.path = path;
    }

    public String getTxHash() {
        return this.txHash;
    }

    public List<Node> getPath() {
        return this.path;
    }

    public int getHeight() {
        return this.height;
    }

    public String getMerkleRootHash() {
        return this.merkleRootHash;
    }
}

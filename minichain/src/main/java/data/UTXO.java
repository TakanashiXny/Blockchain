package data;

import utils.SecurityUtil;

import java.security.KeyPair;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.util.Arrays;
import java.util.Stack;

public class UTXO {
    private final String walletAddress;
    private final int amount;
    private final byte[] publicKeyHash;

    /**
     * 构建一个UTXO
     * @param walletAddress 交易获得方的钱包地址
     * @param amount 比特币数据
     * @param publicKey 交易获得方的公钥
     */
    public UTXO(String walletAddress, int amount, PublicKey publicKey) {
        this.walletAddress = walletAddress;
        this.amount = amount;
        // 对公钥进行哈希摘要，Ripemd160Digest作为解锁脚本的数据
        this.publicKeyHash = SecurityUtil.ripemd160Digest(SecurityUtil.sha256Digest(publicKey.getEncoded()));
    }

    public boolean unlockScript(byte[] sign, PublicKey publicKey) {
        Stack<byte[]> stack = new Stack<>();
        // <sig>签名入栈
        // 栈内：<sig>
        stack.push(sign);
        // <PubK> 公钥入栈
        // 栈内：<sig> <PubK>
        stack.push(publicKey.getEncoded());
        // 复制一份栈顶数据
        // 栈内：<sig> <PubK> <PubK>
        stack.push(stack.peek());
        // HASH160 弹出栈顶元素，进行哈希摘要
        // 栈内：<sig> <PubK> <PubHash>
        byte[] data = stack.pop();
        stack.push(SecurityUtil.ripemd160Digest(SecurityUtil.sha256Digest(data)));
        // 原公钥哈希入栈
        // 栈内：<sig> <PubK> <PubHash> <PubHash>
        stack.push(publicKeyHash);
        // 比较公钥哈希是否相同
        byte[] publicKey1 = stack.pop();
        byte[] publicKey2 = stack.pop();
        if (!Arrays.equals(publicKey1, publicKey2)) {
            return false;
        }

        // 检查签名是否正确
        byte[] publicKeyEncoded = stack.pop();
        byte[] sign1 = stack.pop();

        return SecurityUtil.verify(publicKey.getEncoded(), sign1, publicKey);
    }

    public String getWalletAddress() {
        return walletAddress;
    }

    public int getAmount() {
        return amount;
    }

    public byte[] getPublicKeyHash() {
        return publicKeyHash;
    }

    @Override
    public String toString() {
        return "\n\tUTXO{" +
                "walletAddress='" + walletAddress + '\'' +
                ", amount=" + amount +
                ", publicKeyHash=" + SecurityUtil.bytes2HexString(publicKeyHash) +
                '}';
    }
}

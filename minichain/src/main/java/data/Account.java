package data;

import utils.Base58Util;
import utils.SecurityUtil;

import java.security.KeyPair;
import java.security.PrivateKey;
import java.security.PublicKey;

public class Account {
    private final PublicKey publicKey;
    private final PrivateKey privateKey;

    public Account() {
        KeyPair keyPair = SecurityUtil.secp256k1Generate();
        this.publicKey = keyPair.getPublic();
        this.privateKey = keyPair.getPrivate();
    }

    public PublicKey getPublicKey() {
        return publicKey;
    }

    public PrivateKey getPrivateKey() {
        return privateKey;
    }



    @Override
    public String toString() {
        return "Account{" +
                "publicKey=" + SecurityUtil.bytes2HexString(publicKey.getEncoded()) +
                ", privateKey=" + SecurityUtil.bytes2HexString(privateKey.getEncoded()) +
                '}';
    }

    /**
     * 根据账户的公钥计算钱包地址
     * @return
     */
    public String getWalletAddress() {
        // 公钥哈希
        byte[] publicKeyHash = SecurityUtil.ripemd160Digest(SecurityUtil.sha256Digest(publicKey.getEncoded()));

        // 0x00+公钥哈希
        byte[] data = new byte[1+publicKeyHash.length];
        data[0] = (byte) 0;
        for (int i = 0; i < publicKeyHash.length; i++) {
            data[i+1] = publicKeyHash[i];
        }

        // 两次sha256获取哈希摘要
        byte[] doubleHash = SecurityUtil.sha256Digest(SecurityUtil.sha256Digest(data));

        // 0x00+公钥哈希+校验（两次哈希后前4字节）
        byte[] walletEncoded = new byte[1 + doubleHash.length + 4];
        walletEncoded[0] = (byte) 0;
        for (int i = 0; i < publicKeyHash.length; i++) {
            walletEncoded[i+1] = publicKeyHash[i];
        }
        for (int i = 0; i < 4; i++) {
            walletEncoded[1 + publicKeyHash.length + i] = doubleHash[i];
        }

        // 对二进制地址进行BASE58编码，得到钱包地址（字符串形式）
        String walletAddress = Base58Util.encode(walletEncoded);
        return walletAddress;
    }

    /**
     * 根据未使用的utxo计算账户的余额
     * @param trueUtxos
     * @return
     */
    public int getAmount(UTXO[] trueUtxos) {
        int amount = 0;
        for (UTXO trueUtxo : trueUtxos) {
            amount += trueUtxo.getAmount();
        }
        return amount;
    }
}

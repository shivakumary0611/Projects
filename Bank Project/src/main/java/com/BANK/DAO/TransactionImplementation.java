package com.BANK.DAO;

import com.BANK.Connection.Connector;
//import com.BANK.DTO.Customer;
import com.BANK.DTO.Transaction;
import com.BANK.DTO.TransactionID;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;

public class TransactionImplementation implements TransactionDAO {
    Connection con;

    public TransactionImplementation() {
        this.con = Connector.requestConnection();
    }







    @Override
    public boolean insertTransaction(Transaction t) {

        String query = "INSERT INTO passbook (tran_id, user_acc, rec_acc, tran_date, tran_type, amount, balance) VALUES (?, ?, ?, SYSDATE(), ?, ?, ?)";
        int i = 0;
        try {
            PreparedStatement ps = con.prepareStatement(query);

            ps.setLong(1,TransactionID.generateTransactionId());
            ps.setLong(2, t.getUser_acc());
            ps.setLong(3, t.getRec_acc());
//            ps.setString(4, t.getTran_date());
            ps.setString(4, t.getTran_type());
            ps.setDouble(5,t.getAmount());
            ps.setDouble(6, t.getBalance());


            i = ps.executeUpdate();




        } catch (SQLException e) {
            throw new RuntimeException(e);
        }

        if (i>0) return true;

        return false;
    }












    @Override
    public ArrayList<Transaction> getTransaction(long user) {
        ArrayList<Transaction> transaction = new ArrayList<>();
        String query = "SELECT * FROM PASSBOOK where user_acc = ? order by tran_date desc";
        Transaction t = null;

        try {
            PreparedStatement ps = con.prepareStatement(query);

            ps.setLong(1, user);

            ResultSet rs = ps.executeQuery();

            while(rs.next()){
                t = new Transaction();
                t.setTran_id(rs.getLong("tran_id"));
                t.setUser_acc(rs.getLong("user_acc"));
                t.setRec_acc(rs.getLong("rec_acc"));
                t.setTran_date(rs.getString("tran_date"));
                t.setTran_type(rs.getString("tran_type"));
                t.setAmount(rs.getDouble("amount"));
                t.setBalance(rs.getDouble("balance"));
                transaction.add(t);

            }

        } catch (SQLException e) {
            throw new RuntimeException(e);
        }

        return transaction;
    }





















    @Override
    public ArrayList<Transaction> getTransaction() {
        ArrayList<Transaction> transaction = new ArrayList<>();
        String query = "SELECT * FROM PASSBOOK order by tran_date desc";
        Transaction t = null;

        try {
            PreparedStatement ps = con.prepareStatement(query);


            ResultSet rs = ps.executeQuery();

            while(rs.next()){
                t = new Transaction();
                t.setTran_id(rs.getLong("tran_id"));
                t.setUser_acc(rs.getLong("user_acc"));
                t.setRec_acc(rs.getLong("rec_acc"));
                t.setTran_date(rs.getString("tran_date"));
                t.setTran_type(rs.getString("tran_type"));
                t.setAmount(rs.getDouble("amount"));
                t.setBalance(rs.getDouble("balance"));
                transaction.add(t);

            }

        } catch (SQLException e) {
            throw new RuntimeException(e);
        }

        return transaction;
    }
}















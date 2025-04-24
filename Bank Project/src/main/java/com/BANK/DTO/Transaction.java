package com.BANK.DTO;

//import com.BANK.DAO.TransactionImplementation;

public class Transaction {

    private long tran_id;
    private long user_acc;
    private long rec_acc;
    private String tran_date;
    private String tran_type;
    private double ammount;
    private double balance;


    public long getTran_id() {
        return tran_id;
    }

    public void setTran_id(long tran_id) {
        this.tran_id = tran_id;
    }

    public long getUser_acc() {
        return user_acc;
    }

    public void setUser_acc(long user_acc) {
        this.user_acc = user_acc;
    }

    public long getRec_acc() {
        return rec_acc;
    }

    public void setRec_acc(long rec_acc) {
        this.rec_acc = rec_acc;
    }

    public String getTran_date() {
        return tran_date;
    }

    public void setTran_date(String tran_date) {
        this.tran_date = tran_date;
    }

    public String getTran_type() {
        return tran_type;
    }

    public void setTran_type(String tran_type) {
        this.tran_type = tran_type;
    }

    public double getAmount() {
        return ammount;
    }

    public void setAmount(double ammount) {
        this.ammount = ammount;
    }

    public double getBalance() {
        return balance;
    }

    public void setBalance(double balance) {
        this.balance = balance;
    }


    @Override
    public String toString() {
        return "Transaction{" +
                "tran_id=" + tran_id +
                ", user_acc=" + user_acc +
                ", rec_acc=" + rec_acc +
                ", tran_date='" + tran_date + '\'' +
                ", tran_type='" + tran_type + '\'' +
                ", ammount=" + ammount +
                ", balance=" + balance +
                '}';
    }

   }

package com.BANK.DAO;

import com.BANK.DTO.Transaction;

import java.util.ArrayList;

public interface TransactionDAO {

    public boolean insertTransaction(Transaction t);
    public ArrayList<Transaction> getTransaction(long user);
    public ArrayList<Transaction> getTransaction();
}

package com.BANK.DAO;

import com.BANK.DTO.Customer;

import java.util.ArrayList;

public interface CustomerDAO {

    public long insertCustomer(Customer c); //signup
    public boolean updateCustomer(Customer c);
    public boolean deleteCustomer(Customer c);

    public Customer getCustomer(long acc_no, int pin); // login
    public Customer getCustomer(long phone, String mail);
    public Customer getCustomer(long acc_no);


    public ArrayList<Customer> getCustomer();
}

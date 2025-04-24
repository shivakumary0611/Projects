package com.BANK.DAO;

import com.BANK.Connection.Connector;
import com.BANK.DTO.Customer;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;

public class CustomerImplementation implements CustomerDAO {

    Connection con ;
    public CustomerImplementation() {
        this.con = Connector.requestConnection();
    }



//    -----------------------------SIGN UP-------------------------------------------
    @Override
    public long insertCustomer(Customer c) {
        int i = 0;

        String query = "INSERT INTO CUSTOMER (name,phone,mail, pin) VALUES (?,?,?,?)";

        try {
            PreparedStatement ps = con.prepareStatement(query,PreparedStatement.RETURN_GENERATED_KEYS);
            ps.setString(1,c.getName());
            ps.setLong(2,c.getPhone());
            ps.setString(3,c.getMail());
            ps.setInt(4,c.getPin());

            i = ps.executeUpdate();


//            this is to get auto incremented Number ie Account Number...............
            if (i>0){
                ResultSet rs = ps.getGeneratedKeys();
                if(rs.next()){
                    long generatedaccno = rs.getLong(1);
                    c.setAcc_no(generatedaccno);
                    return generatedaccno;

                    
                }

            }

        } catch (SQLException e) {
            e.printStackTrace();

        }
        return 0;
    }





//    --------------------------------Sign Up End---------------------------------------





// ---------------------------------LOGIN---------------------------------------
    @Override
    public Customer getCustomer(long acc_no, int pin) {
        String query = " SELECT * FROM CUSTOMER WHERE ACC_NO = ? AND PIN = ? ";
        Customer c = null;


        try {
            PreparedStatement ps = con.prepareStatement(query);

            ps.setLong(1,acc_no);
            ps.setInt(2,pin);

            ResultSet rs = ps.executeQuery();

            if (rs.next()){
                c=new Customer();
                c.setAcc_no(rs.getLong("ACC_NO"));
                c.setName(rs.getString("NAME"));
                c.setPhone(rs.getLong("PHONE"));
                c.setMail(rs.getString("MAIL"));
                c.setBalance(rs.getDouble("BALANCE"));
                c.setPin(rs.getInt("PIN"));
            }


        } catch (SQLException e) {
            e.printStackTrace();
        }


        return c;
    }

//  ---------------------------------------LOGIN END-----------------------------------------



//    public Customer getCustomer(long acc_no)  is used for transaction it

    @Override
    public Customer getCustomer(long acc_no) {

        String query = " SELECT * FROM CUSTOMER WHERE ACC_NO = ? ";
        Customer c = null;
        try {
            PreparedStatement ps = con.prepareStatement(query);

            ps.setLong(1,acc_no);

            ResultSet rs = ps.executeQuery();

            if (rs.next()){
                c=new Customer();
                c.setAcc_no(rs.getLong("ACC_NO"));
                c.setName(rs.getString("NAME"));
                c.setPhone(rs.getLong("PHONE"));
                c.setMail(rs.getString("MAIL"));
                c.setBalance(rs.getDouble("BALANCE"));
                c.setPin(rs.getInt("PIN"));
            }


        } catch (SQLException e) {
            e.printStackTrace();
        }


        return c;
    }


//---------------------------------------------------------------------------------------------------




//    this is use get AutoIncremented account number during signup
//    @Override
    public Customer getCustomer(long phone, String mail) {
        Customer c = null;
        String query = "select * from Customer where phone = ? and mail = ?";
        try {
            PreparedStatement ps = con.prepareStatement(query);
            ps.setLong(1,phone);
            ps.setString(2,mail);

            ResultSet rs = ps.executeQuery();

            while (rs.next()){
               c = new Customer();
               c.setAcc_no(rs.getLong("acc_no"));
               c.setName(rs.getString("name"));
               c.setPhone(rs.getLong("phone"));
               c.setMail(rs.getString("mail"));
               c.setBalance(rs.getDouble("balance"));
               c.setPin(rs.getInt("pin"));
            }
        } catch (SQLException e) {
e.printStackTrace();
        }


        return c;
    }






    @Override
    public boolean updateCustomer(Customer c) {
        String query = "Update Customer SET NAME = ?, PHONE = ?, Mail = ?, balance = ?,  PIN = ? where ACC_NO = ?";
        int i = 0;

        try {
            PreparedStatement ps = con.prepareStatement(query);

            ps.setString(1,c.getName());
            ps.setLong(2,c.getPhone());
            ps.setString(3,c.getMail());
            ps.setDouble(4,c.getBalance());
            ps.setInt(5,c.getPin());
            ps.setLong(6,c.getAcc_no());

            i = ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }

        if (i>0) return true;
        return false;
    }





//  ------------------------------DELETE ------------------------------------------------


    @Override
    public boolean deleteCustomer(Customer c) {
        int i = 0;
        String query = "DElETE FROM CUSTOMER WHERE ACC_NO = ?";

        try {
            PreparedStatement ps = con.prepareStatement(query);
            ps.setLong(1,c.getAcc_no());

            i = ps.executeUpdate();

        } catch (SQLException e) {
            throw new RuntimeException(e);
        }

        if (i>0){
            return true;
        }

        return false;
    }




//  ------------------------------DELETE ENDS------------------------------------------------











//    --------------------------Get All Customers ------------------------------------------

    @Override
    public ArrayList<Customer> getCustomer() {
        ArrayList<Customer> customerdetails = new ArrayList<>();
        String query = " select * from customer where acc_no!= 1100110011";
        Customer c = null;
        try {
            PreparedStatement ps = con.prepareStatement(query);

            ResultSet rs = ps.executeQuery();
            while (rs.next()){
                c = new Customer();
                c.setAcc_no(rs.getLong("ACC_NO"));
                c.setName(rs.getString("NAME"));
                c.setPhone(rs.getLong("PHONE"));
                c.setMail(rs.getString("MAIL"));
                c.setBalance(rs.getDouble("BALANCE"));
                customerdetails.add(c);

            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return customerdetails;
    }
}

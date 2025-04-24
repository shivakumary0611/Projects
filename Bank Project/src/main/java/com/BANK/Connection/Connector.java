package com.BANK.Connection;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class Connector {

    public static Connection requestConnection() {
        Connection con = null;
        String url = "jdbc:mysql://localhost:3306/bank";
        String user = "root";
        String password = "9611960286";

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");


            con = DriverManager.getConnection(url, user, password);



        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
        }

        return con;
    }
}

package com.BANK.Servlet;

import java.io.IOException;

import com.BANK.DAO.CustomerDAO;
import com.BANK.DTO.Customer;
import com.mysql.cj.Session;
import com.BANK.DAO.CustomerImplementation;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/LoginServlet")
public class Login extends HttpServlet{

	
	CustomerDAO cdao = new CustomerImplementation();
	
	
	
	
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		
		//retriving feilds from ui and placing in acc and pin
		long acc = Long.parseLong(req.getParameter("acc_no")) ;
		int pin = Integer.parseInt(req.getParameter("pin"));
		
		//session created
		HttpSession session = req.getSession(true);

		//calling getcustomer by accno and pin
		Customer user = cdao.getCustomer(acc, pin);
		
		if(user!=null) {
		//storing customer obj inside session
		session.setAttribute("customer", user);
		resp.sendRedirect("home.jsp");
		}else {
		
		session.setAttribute("failtologin", "invalid Account_No or password Please Try again...");
		resp.sendRedirect("login.jsp");
		}
	
	}
	
	
}

package com.BANK.Servlet;

import java.io.IOException;

import com.BANK.DAO.CustomerDAO;
import com.BANK.DAO.CustomerImplementation;
import com.BANK.DTO.Customer;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/SignupServlet")
public class Signup extends HttpServlet{
	
	
	
	CustomerDAO cdao = new CustomerImplementation();

	Customer user = new Customer();
	
	
	
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		user.setName(req.getParameter("name"));
		user.setPhone(Long.parseLong(req.getParameter("phone")));
		user.setMail(req.getParameter("mail"));
		
		
		if(Integer.parseInt(req.getParameter("pin")) == Integer.parseInt(req.getParameter("confirm_pin"))) {
			user.setPin(Integer.parseInt(req.getParameter("pin")));
			long accno = cdao.insertCustomer(user);
			req.setAttribute("signupsuccess", "signup successfull.. Your Account Number is "+accno);
			RequestDispatcher rd = req.getRequestDispatcher("login.jsp");
			rd.forward(req, resp);
			
			
	}else {
		req.setAttribute("signupfailed", "password mismatch...");
		RequestDispatcher rd = req.getRequestDispatcher("signup.jsp");
		rd.forward(req, resp);
	}
}
}
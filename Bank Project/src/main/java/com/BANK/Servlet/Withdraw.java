package com.BANK.Servlet;

import java.io.IOException;

import com.BANK.DAO.CustomerDAO;
import com.BANK.DAO.CustomerImplementation;
import com.BANK.DTO.Customer;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/WithdrawServlet")
public class Withdraw extends HttpServlet{
	
	CustomerDAO cdao = new CustomerImplementation();
	
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		
		
		HttpSession session = req.getSession(false);
		
		
		
		
		
		
		if(session == null || session.getAttribute("customer") == null) {
			session.setAttribute("sessionexpired", "Please Login to your account");
			resp.sendRedirect("login.jsp");
			return;
		}
		
		
		
		
		
		
		
		Customer user = (Customer) session.getAttribute("customer");
		
		int pin = Integer.parseInt(req.getParameter("pin"));
		double withdraw =Double.parseDouble( req.getParameter("ammount"));
		double balance = user.getBalance();
		if(pin == user.getPin() && withdraw>0 && withdraw<balance) {
			
			double wm = balance-withdraw; 
			user.setBalance(wm);
			cdao.updateCustomer(user);
			
		}
		
		
		if(user!=null) {
			session.setAttribute("withdrawsuccess", "withdrawl completed successfully");
			resp.sendRedirect("withdraw.jsp");
		}else {
			session.setAttribute("withdrawfail", "withdrawl failed ");
			resp.sendRedirect("withdraw.jsp");
		}
		
		
	}

}

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

@WebServlet("/DepositServlet")
public class Deposit extends HttpServlet{
	

	CustomerDAO cdao = new CustomerImplementation();
	
	@SuppressWarnings("unused")
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		
		HttpSession session = req.getSession(false);
		
		
		
		if(session == null || session.getAttribute("customer") == null) {
			session.setAttribute("sessionexpired", "Please Login to your account");
			resp.sendRedirect("login.jsp");
			return;
		}
		
		
		
		
		
		
		 Customer user = (Customer) session.getAttribute("customer"); // Get the user object from session
		
		int pin = Integer.parseInt(req.getParameter("pin"));
		
		if(pin == user.getPin())  {
			double deposit = Double.parseDouble(req.getParameter("money"));
			 deposit += user.getBalance();
			user.setBalance(deposit);
			 cdao.updateCustomer(user);
			
		}
		
		if(user!=null) {
			session.setAttribute("depositsuccess", "Ammount deposited...");
			resp.sendRedirect("deposit.jsp");
		}else {
			session.setAttribute("depositerror", "failed to deposited...");
			resp.sendRedirect("deposit.jsp");
		}
		
		
		
	
	}
	
}
	



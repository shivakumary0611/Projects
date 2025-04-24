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

@WebServlet("/deleteaccount")
public class Deleteuser extends HttpServlet{
	
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		CustomerDAO cdao = new CustomerImplementation();
		HttpSession session = req.getSession(false);
		
		if(session == null || session.getAttribute("customer") == null) {
			session.setAttribute("sessionexpired", "Please Login to your account");
			resp.sendRedirect("login.jsp");
			return;
		}
		
		
		
		Customer user = (Customer) session.getAttribute("customer");
		int accNo = Integer.parseInt(req.getParameter("acc_no")); // Get the account number from the form
		Customer delete = cdao.getCustomer(accNo);
		
		double adminbalance = user.getBalance();
		double deletebalance = delete.getBalance();
		if(delete!=null) {
		adminbalance += deletebalance;
		user.setBalance(adminbalance);
		cdao.updateCustomer(user);
		cdao.deleteCustomer(delete);
		
		session.setAttribute("deletesuccess", "Account Deleted...");
		resp.sendRedirect("allcustomer.jsp");
		}
		
		
	
		
	}

}

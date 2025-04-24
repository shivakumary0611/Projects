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


@WebServlet("/ProfileServlet")
public class Profile extends HttpServlet{
	
	
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
		
		user.setAcc_no(Long.parseLong(req.getParameter("acc_no")));
		
		user.setName(req.getParameter("name"));
		user.setPhone(Long.parseLong(req.getParameter("phone")));
		user.setMail(req.getParameter("email"));
		user.setPin(Integer.parseInt(req.getParameter("pin")));
		
		
		cdao.updateCustomer(user);
		
		
		
		if(user!=null) {
			session.setAttribute("updatesuccess", "Details Updated...");
			resp.sendRedirect("profile.jsp");
			
		}else {
			session.setAttribute("updateerror", "Failed to Updated Details ...");
			resp.sendRedirect("profile.jsp");
		}
		
		
		
		
	}
	

}

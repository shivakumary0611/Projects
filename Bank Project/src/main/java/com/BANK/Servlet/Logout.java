package com.BANK.Servlet;

import java.io.IOException;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/logout")
public class Logout extends HttpServlet {
	
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		
		HttpSession session = req.getSession(false);
		
		
		if (session != null) {
			session.invalidate();  // Destroy session after redirect
		}
		
		RequestDispatcher rd = req.getRequestDispatcher("login.jsp");
		req.setAttribute("logout", "You have successfully logged out");
		rd.forward(req, resp);
		
	}
}

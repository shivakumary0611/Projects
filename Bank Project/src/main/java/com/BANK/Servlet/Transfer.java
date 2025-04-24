package com.BANK.Servlet;

import java.io.IOException;

import com.BANK.DAO.CustomerDAO;
import com.BANK.DAO.CustomerImplementation;
import com.BANK.DAO.TransactionDAO;
import com.BANK.DAO.TransactionImplementation;
import com.BANK.DTO.Customer;
import com.BANK.DTO.Transaction;
import com.BANK.DTO.TransactionID;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/Transfer")
public class Transfer extends HttpServlet{
	
	TransactionDAO tdao = new TransactionImplementation();
	Transaction t1 = null;
	Transaction t2 = null;
	
	
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		
		CustomerDAO cdao = new CustomerImplementation();
		
		HttpSession session = req.getSession(false);
		
		
		
		if(session == null || session.getAttribute("customer") == null) {
			session.setAttribute("sessionexpired", "Please Login to your account");
			resp.sendRedirect("login.jsp");
			return;
		}
		
		
		
		
		
		Customer user = (Customer) session.getAttribute("customer"); // customer / current object
		Long rec = Long.parseLong(req.getParameter("reciveraccno")); // acceccing reciver account no from ui
		double amount = Double.parseDouble(req.getParameter("amount"));
		
	
		
		Customer reciver = cdao.getCustomer(rec); // reciver object recived
		if(reciver == null) {
				session.setAttribute("usernotfound", "User not found...");
				resp.sendRedirect("transfer.jsp");
				return ;

			
		}
		
		if(Integer.parseInt(req.getParameter("pin")) != user.getPin()) {
            session.setAttribute("wrongpin", "Incorrect PIN. Transaction failed.");
            resp.sendRedirect("transfer.jsp");
            return;

		}
		
		
		if(user.getAcc_no() != reciver.getAcc_no() && user.getBalance()>0 && user.getBalance()>= amount &&  amount >0) {
			
			

			
			boolean s_user = false;
			double userbalance = user.getBalance() - amount;
			user.setBalance(userbalance);
			s_user = cdao.updateCustomer(user);
			if(s_user) {
				t1 = new Transaction();
				t1.setTran_id(TransactionID.generateTransactionId());
				t1.setUser_acc(user.getAcc_no());
				t1.setRec_acc(reciver.getAcc_no());
				t1.setTran_type("DEBITED");
				t1.setAmount(amount);
				t1.setBalance(user.getBalance());
				tdao.insertTransaction(t1);
				
			}
			
			boolean r_reciver = false;
			double reciverbalance = reciver.getBalance() + amount;
			reciver.setBalance(reciverbalance);
			r_reciver = cdao.updateCustomer(reciver);
			if(r_reciver) {
				t2 = new Transaction();
				t2.setTran_id(t1.getTran_id());
				t2.setUser_acc(reciver.getAcc_no());
				t2.setRec_acc(user.getAcc_no());
				t2.setTran_type("CREDITED");
				t2.setAmount(amount);
				t2.setBalance(reciver.getBalance());
				tdao.insertTransaction(t2);
			}
			
			
			if(s_user && r_reciver) {
			    session.setAttribute("transferedamount", amount); // Set after successful transfer

				session.setAttribute("transfersuccess", "Amount Transfered Successfull...");
				resp.sendRedirect("transfer.jsp");
			}else {
	            session.setAttribute("transferfailed", "Transaction failed. Please try again.");
				resp.sendRedirect("transfer.jsp");


			}
			
		}else {
			session.setAttribute("accountcredentials", "Please check Account Credintials");
			resp.sendRedirect("transfer.jsp");
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}

}

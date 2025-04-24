<%@page import="com.BANK.DTO.Transaction"%>
<%@page import="com.BANK.DAO.TransactionDAO"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
    
    <%@page import = "com.BANK.DAO.TransactionDAO" %>
        <%@page import = "com.BANK.DTO.Customer" %>
    
    <%@page import = "com.BANK.DAO.TransactionImplementation" %>
        <%@page import = "java.util.ArrayList" %>
    

    
    
    
    <!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Passbook</title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

    <style>
        body {
            font-family: 'Poppins', sans-serif;
            padding-top: 80px;
            background: #ffffff;
        }
        .container {
            margin-top: 50px;
        }
        .passbook-card {
            padding: 20px;
            background: white;
            box-shadow: 0px 4px 12px rgba(0, 0, 0, 0.1);
            border-radius: 15px;
        }
        .navbar-nav .nav-link {
            position: relative;
            padding-bottom: 5px;
            margin-right: 20px;
            color: black;
        }
        .navbar-nav .nav-link::after {
            content: "";
            position: absolute;
            left: 50%;
            bottom: 0;
            width: 0;
            height: 2px;
            background-color: #007BFF;
            transition: all 0.3s ease;
            transform: translateX(-50%);
        }
        .navbar-nav .nav-link:hover::after {
            width: 100%;
        }
    </style>
</head>
<body>
    
    <!-- Navbar -->
    <nav class="navbar navbar-expand-lg navbar-light bg-light fixed-top">
        <div class="container">
            <a class="navbar-brand d-flex align-items-center" href="home.jsp">
                <img src="https://img.icons8.com/external-flatart-icons-flat-flatarticons/64/external-bank-hotel-services-and-city-elements-flatart-icons-flat-flatarticons.png" alt="Bank Logo" height="40" class="me-2"> 
                <span>MyBank</span>
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav mx-auto">
                    <li class="nav-item"><a class="nav-link" href="home.jsp">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="#about">About</a></li>
                    <li class="nav-item"><a class="nav-link" href="#contact">Contact</a></li>
                </ul>
                
                
                <a href="home.jsp" class="btn btn-secondary me-2">Back</a>



            </div>
        </div>
    </nav>
    
    <!-- Passbook Section -->
    <div class="container">
        <div class="passbook-card p-4">
            <h4 class="text-center mb-4">Passbook</h4>
            <table class="table table-bordered text-center">
                <thead class="table-dark">
                    <tr>
                        <th>Transaction ID</th>
                        <th>Account Number</th>
                        <th>Transaction Type</th>
                        <th>Date</th>
                        <th>Amount</th>
                    </tr>
                </thead>
                <tbody>
                <%Customer user = (Customer) session.getAttribute("customer"); %>
                <%TransactionDAO tdao = new TransactionImplementation();
                ArrayList <Transaction> al = new ArrayList<>(); 
                %>
                <%al = tdao.getTransaction(user.getAcc_no()); %>
                
                
                <%for(Transaction list: al){ %>
                
                
                
                    <!-- Dynamic Data Here -->
                    <tr>
                        <td><%=list.getTran_id() %></td>
                        <td><%=list.getRec_acc() %></td>
						<td style="color: <%= list.getTran_type().equalsIgnoreCase("CREDITED") ? "green" : "red" %>;"><%=list.getTran_type() %></td>
                        <td><%=list.getTran_date() %></td>
                        <td>₹<%=list.getAmount() %></td>
                    </tr>
                  <%} %>
                </tbody>
            </table>
        </div>
    </div>

</body>
</html>
    
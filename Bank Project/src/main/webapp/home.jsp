<%@page import="com.BANK.DTO.Customer"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

    
    
   
    
    
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bank Dashboard</title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

    <style>
        /* Navbar Styling */
        .navbar {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            background: #ffffff;
            box-shadow: 0px 4px 12px rgba(0, 0, 0, 0.1);
            padding: 10px 20px;
            z-index: 1000;
        }
        .navbar-brand img {
            height: 50px;
            margin-right: 10px;
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
        .logout-btn {
            background-color: red;
            border: none;
            color: white;
        }

        /* General Styles */
        body {
            background: #ffffff;
            color: #1E1E50;
            font-family: 'Poppins', sans-serif;
            padding-top: 80px;
        }

        /* Dashboard Container */
        .dashboard-container {
            max-width: 900px;
            margin: auto;
            padding: 20px;
            text-align: center;
        }

        /* User Card */
        .user-card {
            max-width: 500px;
            margin: auto;
            padding: 20px;
            background: white;
            box-shadow: 0px 4px 12px rgba(0, 0, 0, 0.1);
            border-radius: 15px;
            text-align: center;
        }

        /* Cards Container */
        .cards-container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }

        .card {
            padding: 20px;
            text-align: center;
            box-shadow: 0px 4px 12px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s ease;
            border-radius: 10px;
        }
        .card:hover {
            transform: scale(1.05);
        }

        /* About Section */
        .about-section {
            background: #f8f9fa;
            padding: 40px 20px;
            text-align: center;
            margin-top: 20px;
            margin-bottom: 40px;
        }
        .about-section h2 {
            margin-bottom: 40px;
        }

        /* Footer */
        .footer {
            background: #343a40;
            color: white;
            padding: 20px 0;
            text-align: center;
        }


        
    </style>
</head>
<body>

<%Customer user = (Customer)session.getAttribute("customer"); %>

    <!-- Navbar -->
    <nav class="navbar navbar-expand-lg">
        <div class="container d-flex justify-content-between align-items-center">
            <a class="navbar-brand d-flex align-items-center" href="home.jsp">
                <img src="https://img.icons8.com/external-flatart-icons-flat-flatarticons/64/external-bank-hotel-services-and-city-elements-flatart-icons-flat-flatarticons.png" alt="Bank Logo"> 
                <span>MyBank</span>
            </a>
            <div class="collapse navbar-collapse justify-content-center">
                <ul class="navbar-nav">
                    <li class="nav-item"><a class="nav-link" href="home.jsp">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="#about">About</a></li>
                    <li class="nav-item"><a class="nav-link" href="#">Contact</a></li>
                </ul>
            </div>
            <span class="me-2">Languages:</span>
            <select class="form-select w-auto" id="language-selector">
                <option value="en">English</option>
                <option value="es">Español</option>
                <option value="fr">Français</option>
                <option value="de">Deutsch</option>
                <option value="hi">हिन्दी</option>
            </select>
            <form action="logout" method="get">
            <button class="btn logout-btn ms-2" >Logout</button>
            </form>
        </div>
    </nav>

	

    <!-- Dashboard -->
    <div class="dashboard-container">
        <div class="user-card">
            <img src="https://img.icons8.com/bubbles/100/000000/user.png" alt="User Profile">
            <h5>Welcome <%=user.getName() %></h5>
            <p>Account Number: <%=user.getAcc_no() %></p>
            <p>Email: <%=user.getMail() %></p>
        </div>

        <div class="cards-container">
        
        
        
        
            <div class="card bg-primary text-white">
                <h5>Account Balance</h5>
                <h3>₹<%=user.getBalance() %></h3>
            </div>
            <div class="card bg-success text-white">
                <h5>Deposit Money</h5>
                <a href="deposit.jsp" class="btn btn-light btn-sm">Deposit</a>
            </div>
            <div class="card bg-danger text-white">
                <h5>Withdraw Money</h5>
                <a href="withdraw.jsp" class="btn btn-light btn-sm">Withdraw</a>
            </div>
            <div class="card bg-warning text-dark">
                <h5>Transfer Money</h5>
                <a href="transfer.jsp" class="btn btn-dark btn-sm">Transfer</a>
            </div>
            <div class="card bg-info text-white">
                <h5>Transaction History</h5>
                <a href="passbook.jsp" class="btn btn-light btn-sm">View Passbook</a>
            </div>
            <div class="card bg-secondary text-white">
                <h5>Update Account Details</h5>
                <a href="profile.jsp" class="btn btn-light btn-sm">Edit Profile</a>
            </div>
            
            
            
            
            <%if(user.getAcc_no() == 1100110011) {%>
	
	<div class="card bg-info text-white">
                <h5>View AllTransaction</h5>
                <a href="alltransaction.jsp" class="btn btn-light btn-sm">Transaction</a>
            </div>
            <div class="card bg-danger text-dark">
                <h5>Delete Customers Account</h5>
                <a href="allcustomer.jsp" class="btn btn-light btn-sm">Delete</a>
            </div>
	
	<%} %>
            
            
            
            
        </div>
    </div>

    <!-- About Section -->
    <div class="about-section" id="about">
        <h2>About MyBank</h2>
        <div id="aboutCarousel" class="carousel slide" data-bs-ride="carousel">
            <div class="carousel-inner">
                <div class="carousel-item active">
                    <h3>Secure Banking 🔐</h3>
                    <p>Your money is safe with advanced encryption and fraud protection.</p>
                </div>
                <div class="carousel-item">
                    <h3>Fast Transactions ⚡</h3>
                    <p>Instant fund transfers and seamless online transactions.</p>
                </div>
                <div class="carousel-item">
                    <h3>24/7 Customer Support ☎️</h3>
                    <p>We’re here for you round the clock, ensuring hassle-free banking.</p>
                </div>
            </div>
        </div>
    </div>

    <!-- Footer -->
       <footer class="footer" id="contact">
        <div class="container">
            <p>&copy; 2025 MyBank. All rights reserved.</p>
            <p>Contact: support@mybank.com | Phone: +91 98765 43210</p>
        </div>
    </footer>

    <script>
        var myCarousel = new bootstrap.Carousel(document.getElementById('aboutCarousel'), {
            interval: 3000,
            ride: 'carousel'
        });
    </script>

</body>
</html>





    
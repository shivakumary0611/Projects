<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

    
    
    
    
    
    
    
    
    
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Withdraw Money</title>
    
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
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }

        /* Withdraw Card */
        .withdraw-card {
            width: 500px;
            padding: 20px;
            background: white;
            box-shadow: 0px 4px 12px rgba(0, 0, 0, 0.1);
            border-radius: 15px;
            text-align: center;
        }
        .withdraw-card img {
            width: 100px;
            margin-bottom: 10px;
        }
        .withdraw-title {
            font-weight: bold;
            margin-bottom: 15px;
            text-decoration: underline;
        }
    </style>
</head>
<body>

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
        </div>
    </nav>

    <!-- Withdraw Money Section -->
    <div class="withdraw-card">
        <h5 class="withdraw-title">Withdraw Money</h5>
        
        
        
       
        
        
        
        
        
        
        <%String withdrawsuccess = (String) session.getAttribute("withdrawsuccess");%>
				<%if (withdrawsuccess != null) {%>
				<div class="alert alert-success d-flex align-items-center"
					role="alert">
					<svg class="bi flex-shrink-0 me-2" width="24" height="24"
						role="img" aria-label="Danger:">
						<use xlink:href="#exclamation-triangle-fill" /></svg>
					<div>
						<%=withdrawsuccess%>
						<%session.removeAttribute("withdrawsuccess");%>
					</div>

				</div>

				<%}%>
        
        
        
        
        
        
        
        
        
        <%String withdrawfail = (String) session.getAttribute("withdrawfail");%>
				<%if (withdrawfail != null) {%>
				<div class="alert alert-danger d-flex align-items-center"
					role="alert">
					<svg class="bi flex-shrink-0 me-2" width="24" height="24"
						role="img" aria-label="Danger:">
						<use xlink:href="#exclamation-triangle-fill" /></svg>
					<div>
						<%=withdrawfail%>
						<%session.removeAttribute("withdrawfail");%>
					</div>

				</div>

				<%}%>
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        <img width="100" height="100" src="https://img.icons8.com/external-nawicon-flat-nawicon/100/external-withdraw-finance-nawicon-flat-nawicon.png" alt="external-withdraw-finance-nawicon-flat-nawicon"/>
        <form action="WithdrawServlet" method="post">
            <div class="mb-3">
                <input type="number" name = "ammount" class="form-control" placeholder="Enter amount to withdraw">
            </div>
            <div class="mb-3">
                <input type="password" name = "pin" class="form-control" placeholder="Enter your PIN">
            </div>
            <button type="submit" class="btn btn-primary">Withdraw</button>
            <a href="home.jsp" class="btn btn-secondary">Back</a>
        </form>
    </div>
</body>
</html>
    
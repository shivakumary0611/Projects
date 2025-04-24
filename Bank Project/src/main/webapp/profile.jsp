<%@page import="com.BANK.DTO.Customer"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

    
    
    
    
    
    
    
    <!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Update Profile</title>
    
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

        /* Profile Card */
        .profile-card {
            width: 500px;
            padding: 20px;
            background: white;
            box-shadow: 0px 4px 12px rgba(0, 0, 0, 0.1);
            border-radius: 15px;
            text-align: center;
        }
        .profile-card img {
            width: 100px;
            margin-bottom: 10px;
        }
        .user-details {
            margin-top: 10px;
        }
        .update-title {
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
    
    
    <% Customer user=(Customer)session.getAttribute("customer");%>
    

    <!-- Profile Update Section -->
    <div class="profile-card">
        <h5 class="update-title">Update Profile</h5>
        
        
        
            
            
            
            
            
            <%String updatesuccess = (String) session.getAttribute("updatesuccess");%>
				<%if (updatesuccess != null) {%>
				<div class="alert alert-success d-flex align-items-center"
					role="alert">
					<svg class="bi flex-shrink-0 me-2" width="24" height="24"
						role="img" aria-label="Danger:">
						<use xlink:href="#exclamation-triangle-fill" /></svg>
					<div>
						<%=updatesuccess%>
						<%session.removeAttribute("updatesuccess");%>
					</div>

				</div>

				<%}%>
				
				
				
				
				
				<%String updateerror = (String) session.getAttribute("updateerror");%>
				<%if (updateerror != null) {%>
				<div class="alert alert-danger d-flex align-items-center"
					role="alert">
					<svg class="bi flex-shrink-0 me-2" width="24" height="24"
						role="img" aria-label="Danger:">
						<use xlink:href="#exclamation-triangle-fill" /></svg>
					<div>
						<%=updateerror%>
						<%session.removeAttribute("updateerror");%>
					</div>

				</div>

				<%}%>
            
            
            
            
            
            
            
            
           
        
        
        
        <img src="https://img.icons8.com/bubbles/100/000000/user.png" alt="User Profile">
        <div class="user-details">
            <h5>John Doe</h5>
            <p>Account Number: 123456789</p>
        </div>
        <form action="ProfileServlet" method = "post">
        
        <div class="mb-3">
                <input type="hidden" class="form-control" value = "<%= user.getAcc_no()%>" name = "acc_no">
            </div>
        
            <div class="mb-3">
                <input type="text" class="form-control" name = "name"   placeholder="Enter your name" value = "<%=user.getName()%>">
            </div>
            <div class="mb-3">
                <input type="text" class="form-control" name = "phone" placeholder="Enter your phone number" value = "<%=user.getPhone()%>">
            </div>
            <div class="mb-3">
                <input type="email" class="form-control" name = "email" placeholder="Enter your email" value = "<%=user.getMail()%>">
            </div>
            <div class="mb-3">
                <input type="password" class="form-control" name = "pin" placeholder="Enter your PIN" value = "<%=user.getPin()%>">
            </div>
            <button type="submit" class="btn btn-primary">Update</button>
            <a href="home.jsp" class="btn btn-secondary">Back</a>
        </form>
    </div>
</body>
</html>
    
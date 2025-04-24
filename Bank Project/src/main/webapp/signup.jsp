<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

    
    
    
    
    
    
    
    
    
    
    
    
    
    
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <title>Bank Sign Up</title>
    <style>
        /* Same styling as Login Page */
        .navbar {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            background: #ffffff !important;
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

        body {
            background: #ffffff;
            color: #1E1E50;
            font-family: 'Poppins', sans-serif;
            height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding-top: 70px;
        }

        .content-container {
            display: flex;
            flex-wrap: wrap;
            width: 80%;
            max-width: 900px;
            background: white;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0px 4px 20px rgba(0, 0, 0, 0.2);
            align-items: center;
        }

        .left {
            flex: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .left img {
            width: 100%;
            max-width: 350px;
        }

        .right {
            flex: 1;
            padding: 40px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            text-align: center;
        }

        .signup-box {
            width: 100%;
            max-width: 350px;
        }

        .signup-logo {
            width: 70px;
            margin-bottom: 15px;
        }

        @media (max-width: 992px) {
            .content-container {
                flex-direction: column;
                width: 90%;
            }
        }

        @media (max-width: 768px) {
            .content-container {
                width: 95%;
            }
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg">
        <div class="container d-flex align-items-center justify-content-between">
            <a class="navbar-brand d-flex align-items-center" href="home.jsp">
                <img src="https://img.icons8.com/external-flatart-icons-flat-flatarticons/64/external-bank-hotel-services-and-city-elements-flatart-icons-flat-flatarticons.png" alt="Bank Logo"> 
                <span>MyBank</span>
            </a>
            <div class="collapse navbar-collapse justify-content-center">
                <ul class="navbar-nav">
                    <li class="nav-item"><a class="nav-link" href="home.jsp">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="#">About</a></li>
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

    <div class="content-container">
        <div class="left">
            <img src="https://img.freepik.com/free-vector/sign-up-concept-illustration_114360-7965.jpg?w=900" alt="Bank Illustration">
        </div>

        <div class="right">
            <div class="signup-box">
                <img src="https://img.icons8.com/external-flatart-icons-flat-flatarticons/64/external-bank-hotel-services-and-city-elements-flatart-icons-flat-flatarticons.png" alt="Signup Logo" class="signup-logo"> 
                <h2>Sign Up</h2>
                
                
                         
				
				
				
				
				
				<%String signupfailed = (String) request.getAttribute("signupfailed");%>
				<%if (signupfailed != null) {%>
				<div class="alert alert-danger d-flex align-items-center"
					role="alert">
					<svg class="bi flex-shrink-0 me-2" width="24" height="24"
						role="img" aria-label="Danger:">
						<use xlink:href="#exclamation-triangle-fill" /></svg>
					<div>
						<%=signupfailed%>
						<%session.removeAttribute("signupfailed");%>
					</div>

				</div>

				<%}%>
				
				
				
				     
                
                
                
                <form action="SignupServlet" method="post">
                    <div class="mb-3">
                        <input type="text" class="form-control" name="name" placeholder="Full Name" required>
                    </div>
                    <div class="mb-3">
                        <input type="tel" class="form-control" name="phone" placeholder="Phone Number" required>
                    </div>
                    <div class="mb-3">
                        <input type="email" class="form-control" name="mail" placeholder="Email Address" required>
                    </div>
                    <div class="mb-3">
                        <input type="password" class="form-control" name="pin" placeholder="Create PIN" required>
                    </div>
                    <div class="mb-3">
                        <input type="password" class="form-control" name="confirm_pin" placeholder="Confirm PIN" required>
                    </div>
                    <button type="submit" class="btn btn-primary w-100">Sign Up</button>
                </form>
                <p class="mt-3">Already have an account? <a href="login.jsp" class="text-info">Login</a></p>
            </div>
        </div>
    </div>
</body>
</html>
    
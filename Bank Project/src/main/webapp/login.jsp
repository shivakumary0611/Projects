<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>









<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link
	href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
	rel="stylesheet">
<script
	src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<title>Bank Login</title>
<style>
/* Ensure Navbar Stays at the Top */
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

.navbar-nav {
	margin: auto; /* Center the nav links */
}

.navbar a {
	color: #000 !important;
	font-weight: 500;
	position: relative;
}

/* Hover Border Effect */
.navbar-nav .nav-link {
	position: relative;
	padding-bottom: 5px;
	margin-right: 20px;
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

/* Adjust Body */
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

/* Login Section */
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

/* Left Side - Image */
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

/* Right Side - Login Form */
.right {
	flex: 1;
	padding: 40px;
	display: flex;
	flex-direction: column;
	justify-content: center;
	align-items: center;
	text-align: center;
}

/* Login Box */
.login-box {
	width: 100%;
	max-width: 350px;
}

/* Login Logo */
.login-logo {
	width: 70px;
	margin-bottom: 15px;
}

/* Responsive Design */
@media ( max-width : 992px) {
	.content-container {
		flex-direction: column;
		width: 90%;
	}
	.left {
		padding: 20px;
	}
}

@media ( max-width : 768px) {
	.navbar {
		padding: 10px;
	}
	.navbar-brand img {
		height: 40px;
	}
	.content-container {
		width: 95%;
	}
}
</style>
</head>
<body>
	<!-- Navbar -->
	<nav class="navbar navbar-expand-lg">
		<div
			class="container d-flex align-items-center justify-content-between">
			<a class="navbar-brand d-flex align-items-center" href="#"> <img
				src="https://img.icons8.com/external-flatart-icons-flat-flatarticons/64/external-bank-hotel-services-and-city-elements-flatart-icons-flat-flatarticons.png"
				alt="Bank Logo"> <span>MyBank</span>
			</a>
			<div class="collapse navbar-collapse justify-content-center">
				<ul class="navbar-nav">
					<li class="nav-item"><a class="nav-link" href="#">Home</a></li>
					<li class="nav-item"><a class="nav-link" href="#">About</a></li>
					<li class="nav-item"><a class="nav-link" href="#">Contact</a></li>
				</ul>
			</div>
			<!-- Language Selector -->
			<span class="me-2">Languages:</span> <select
				class="form-select w-auto" id="language-selector">
				<option value="en">English</option>
				<option value="es">Español</option>
				<option value="fr">Français</option>
				<option value="de">Deutsch</option>
				<option value="hi">हिन्दी</option>
			</select>
		</div>
	</nav>

	<!-- Login Section -->
	<div class="content-container">
		<div class="left">
			<img
				src="https://img.freepik.com/premium-vector/customizable-flat-illustration-mobile-login_9206-2872.jpg?w=900"
				alt="Bank Illustration">
		</div>

		<div class="right">
			<div class="login-box">
				<img
					src="https://img.icons8.com/external-flatart-icons-flat-flatarticons/64/external-bank-hotel-services-and-city-elements-flatart-icons-flat-flatarticons.png"
					alt="Login Logo" class="login-logo">
				<h2>Login</h2>




				
				
				
				
				
				<%String failtologin = (String) session.getAttribute("failtologin");%>
				<%if (failtologin != null) {%>
				<div class="alert alert-danger d-flex align-items-center"
					role="alert">
					<svg class="bi flex-shrink-0 me-2" width="24" height="24"
						role="img" aria-label="Danger:">
						<use xlink:href="#exclamation-triangle-fill" /></svg>
					<div>
						<%=failtologin%>
						<%session.removeAttribute("failtologin");%>
					</div>

				</div>

				<%}%>
				
				
				
				
				





				
				
				<%String signupsuccess = (String) request.getAttribute("signupsuccess");%>
				<%if (signupsuccess != null) {%>
				<div class="alert alert-success d-flex align-items-center"
					role="alert">
					<svg class="bi flex-shrink-0 me-2" width="24" height="24"
						role="img" aria-label="Danger:">
						<use xlink:href="#exclamation-triangle-fill" /></svg>
					<div>
						<%=signupsuccess%>
						<%session.removeAttribute("signupsuccess");%>
					</div>

				</div>

				<%}%>
				
				
				
				
				
				
				
				



				
				
				
				
				
				<%String logout = (String) request.getAttribute("logout");%>
				<%if (logout != null) {%>
				<div class="alert alert-success d-flex align-items-center"
					role="alert">
					<svg class="bi flex-shrink-0 me-2" width="24" height="24"
						role="img" aria-label="Danger:">
						<use xlink:href="#exclamation-triangle-fill" /></svg>
					<div>
						<%=logout%>
						<%session.removeAttribute("logout");%>
					</div>

				</div>

				<%}%>
				
				
				
				
				
				
				
				
				




				<%String sessionexpired = (String) session.getAttribute("sessionexpired");%>
				<%if (sessionexpired != null) {%>
				<div class="alert alert-danger d-flex align-items-center"
					role="alert">
					<svg class="bi flex-shrink-0 me-2" width="24" height="24"
						role="img" aria-label="Danger:">
						<use xlink:href="#exclamation-triangle-fill" /></svg>
					<div>
						<%=sessionexpired%>
						<%session.removeAttribute("sessionexpired");%>
					</div>

				</div>

				<%}%>








				<form action="LoginServlet" method="post">
					<div class="mb-3">
						<input type="text" class="form-control" name="acc_no"
							placeholder="Account Number" required>
					</div>
					<div class="mb-3">
						<input type="password" class="form-control" name="pin"
							placeholder="PIN" required>
					</div>
					<button type="submit" class="btn btn-primary w-100">Login</button>
				</form>
				<p class="mt-3">
					Don't have an account? <a href="signup.jsp" class="text-info">Sign
						Up</a>
				</p>
			</div>
		</div>
	</div>
</body>
</html>

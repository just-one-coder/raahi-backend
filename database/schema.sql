DROP DATABASE IF EXISTS raahi_db;
CREATE DATABASE IF NOT EXISTS raahi_db;
USE raahi_db;

CREATE TABLE User_details (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_key VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(15),
    date_of_birth DATE,
    validation_proof_type VARCHAR(50),
    proof_id_number VARCHAR(100),
    address TEXT,
    preferences JSON, 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Dependency (
    dependency_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    dependent_name VARCHAR(100) NOT NULL,
    relationship VARCHAR(50),
    phone_number VARCHAR(15),
    email VARCHAR(100),
    permissions JSON, 
    FOREIGN KEY (user_id) REFERENCES User_details(user_id) ON DELETE CASCADE
);

CREATE TABLE Location (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    country VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),   
    longitude DECIMAL(10, 8),
    geohraphical_features JSON 
);

CREATE TABLE Hotel (
    hotel_id INT AUTO_INCREMENT PRIMARY KEY,
    hotel_reg_number VARCHAR(100) UNIQUE NOT NULL,
    hotel_name VARCHAR(200) NOT NULL,
    location_id INT,
    hotel_manager VARCHAR(100),
    manager_contact VARCHAR(15),
    hotel_email VARCHAR(100),
    overall_rating DECIMAL(3,2),
    affordability ENUM('Budget', 'Moderate', 'Luxury', 'Premium'),
    amenities JSON, 
    room_types JSON, 
    FOREIGN KEY (location_id) REFERENCES Location(location_id)
);

-- Vacation Spots Table
CREATE TABLE Vacation_Spot (
    spot_id INT AUTO_INCREMENT PRIMARY KEY,
    spot_name VARCHAR(200) NOT NULL,
    location_id INT,
    spot_type VARCHAR(50),
    spot_vibe VARCHAR(100),
    open_time TIME,
    close_time TIME,
    accessibility_info TEXT,
    specialty_description TEXT,
    average_rating DECIMAL(3,2),
    entry_fee DECIMAL(8,2),
    features JSON, 
    activities JSON, 
    FOREIGN KEY (location_id) REFERENCES Location(location_id)
);

CREATE TABLE Trip_Plan (
    trip_id INT AUTO_INCREMENT PRIMARY KEY,
    trip_name VARCHAR(200) NOT NULL,
    user_id INT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    budget DECIMAL(12,2),
    estimated_cost DECIMAL(12,2),
    trip_status ENUM('Planning', 'Booked', 'Ongoing', 'Completed', 'Cancelled'),
    trip_preferences JSON, 
    itinerary JSON, 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User_details(user_id) ON DELETE CASCADE
);

CREATE TABLE Trip_Locations (
    trip_location_id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT,
    location_id INT,
    visit_date DATE,
    duration_hours INT,
    visit_order INT,
    activity_details JSON, 
    FOREIGN KEY (trip_id) REFERENCES Trip_Plan(trip_id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES Location(location_id)
);

CREATE TABLE Travel_Forum (
    forum_post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    trip_id INT,
    post_title VARCHAR(300),
    post_content TEXT,
    travel_dates JSON, 
    preferences JSON, 
    requirements JSON, 
    post_status ENUM('Active', 'Closed', 'Found Companion'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User_details(user_id) ON DELETE CASCADE,
    FOREIGN KEY (trip_id) REFERENCES Trip_Plan(trip_id) ON DELETE SET NULL
);

CREATE TABLE Forum_Response (
    response_id INT AUTO_INCREMENT PRIMARY KEY,
    forum_post_id INT,
    responder_id INT,
    response_text TEXT,
    responder_details JSON, 
    status ENUM('Pending', 'Accepted', 'Rejected'),
    responded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (forum_post_id) REFERENCES Travel_Forum(forum_post_id) ON DELETE CASCADE,
    FOREIGN KEY (responder_id) REFERENCES User_details(user_id) ON DELETE CASCADE
);

CREATE TABLE Payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    trip_id INT,
    amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(50),
    payment_status ENUM('Pending', 'Completed', 'Failed', 'Refunded'),
    gateway_id VARCHAR(200),
    payment_details JSON, 
    payment_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmation_time TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES User_details(user_id) ON DELETE CASCADE,
    FOREIGN KEY (trip_id) REFERENCES Trip_Plan(trip_id) ON DELETE CASCADE
);

CREATE TABLE Review (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    trip_id INT,
    entity_type ENUM('Hotel', 'Vacation_Spot', 'Companion', 'Application'),
    entity_id INT,
    rating DECIMAL(2,1),
    review_text TEXT,
    review_aspects JSON, 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User_details(user_id) ON DELETE CASCADE,
    FOREIGN KEY (trip_id) REFERENCES Trip_Plan(trip_id) ON DELETE CASCADE
);

CREATE TABLE Customer_Support (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    trip_id INT,
    issue_type VARCHAR(100),
    issue_description TEXT NOT NULL,
    status ENUM('Open', 'In Progress', 'Resolved', 'Closed'),
    metadata JSON, 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES User_details(user_id) ON DELETE CASCADE,
    FOREIGN KEY (trip_id) REFERENCES Trip_Plan(trip_id) ON DELETE SET NULL
);

CREATE TABLE Live_Tracking (
    tracking_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    trip_id INT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(10,8),
    location_name VARCHAR(200),
    response TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User_details(user_id) ON DELETE CASCADE,
    FOREIGN KEY (trip_id) REFERENCES Trip_Plan(trip_id) ON DELETE CASCADE
);

CREATE TABLE Emergency_Alert (
    alert_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    trip_id INT,
    location_lat DECIMAL(10,8),
    location_lng DECIMAL(10,8),
    message TEXT,
    status ENUM('Active', 'Resolved'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES User_details(user_id) ON DELETE CASCADE,
    FOREIGN KEY (trip_id) REFERENCES Trip_Plan(trip_id) ON DELETE CASCADE
);

CREATE TABLE Emergency_Notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    alert_id INT,
    dependency_id INT,
    notification_status ENUM('Sent', 'Delivered', 'Read'),
    notification_data JSON, -- Store notification content and responses
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (alert_id) REFERENCES Emergency_Alert(alert_id) ON DELETE CASCADE,
    FOREIGN KEY (dependency_id) REFERENCES Dependency(dependency_id) ON DELETE CASCADE
);

SELECT * FROM User_details;
SELECT * FROM Dependency;
SELECT * FROM Location;
SELECT * FROM Hotel;
SELECT * FROM Vacation_Spot;
SELECT * FROM Trip_Plan;
SELECT * FROM Trip_Locations;
SELECT * FROM Travel_Forum;
SELECT * FROM Forum_Response;
SELECT * FROM Payment;
SELECT * FROM Review;
SELECT * FROM Customer_Support;
SELECT * FROM Live_Tracking;
SELECT * FROM Emergency_Alert;
SELECT * FROM Emergency_Notifications ;
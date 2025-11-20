"""
Test cases for student live session functionality
"""
import unittest
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

class StudentLiveSessionTest(unittest.TestCase):
    """Test cases for student live session functionality"""
    
    def setUp(self):
        """Set up the test environment"""
        self.driver = webdriver.Chrome()
        self.driver.maximize_window()
        self.base_url = "http://localhost:5000"
        self.wait = WebDriverWait(self.driver, 10)
        
        # Login as student
        self.login_as_student()
        
    def tearDown(self):
        """Clean up after the test"""
        self.driver.quit()
        
    def login_as_student(self):
        """Login as a student"""
        self.driver.get(f"{self.base_url}/institution/digikul/login")
        
        # Select student login option
        self.driver.find_element(By.CSS_SELECTOR, "button[data-role='student']").click()
        
        # Fill in login form
        self.driver.find_element(By.ID, "email").send_keys("s1@gmail.com")
        self.driver.find_element(By.ID, "password").send_keys("admin123")
        self.driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
        
        # Wait for dashboard to load
        self.wait.until(EC.presence_of_element_located((By.ID, "student-dashboard")))
        
    def test_join_session(self):
        """Test joining an existing session"""
        # Navigate to sessions list
        self.driver.get(f"{self.base_url}/student/dashboard")
        
        # Click on first available session in list
        self.driver.find_element(By.CSS_SELECTOR, ".session-item:first-child .join-btn").click()
        
        # Verify session joined
        self.wait.until(EC.presence_of_element_located((By.ID, "live-session-container")))
        
    def test_whiteboard_interaction(self):
        """Test whiteboard interaction"""
        # Join a session
        self.test_join_session()
        
        # Get whiteboard canvas
        canvas = self.driver.find_element(By.ID, "whiteboard-canvas")
        
        # Test drawing on whiteboard
        action = webdriver.ActionChains(self.driver)
        action.move_to_element_with_offset(canvas, 50, 50).click_and_hold()
        action.move_to_element_with_offset(canvas, 200, 200).release()
        action.perform()
        
        # Verify drawing occurred (this is a simple check that would need to be enhanced)
        time.sleep(1)  # Allow time for drawing to render
        
    def test_chat_functionality(self):
        """Test chat functionality"""
        # Join a session
        self.test_join_session()
        
        # Send a chat message
        chat_input = self.driver.find_element(By.ID, "chat-input")
        chat_input.send_keys("Test message from student")
        chat_input.submit()
        
        # Verify message appears in chat
        self.wait.until(EC.text_to_be_present_in_element((By.CSS_SELECTOR, ".chat-messages"), "Test message from student"))
        
    def test_participants_list(self):
        """Test participants list functionality"""
        # Join a session
        self.test_join_session()
        
        # Verify participants list is populated
        participants_list = self.driver.find_element(By.ID, "participants-list")
        self.assertIsNotNone(participants_list)
        
        # Verify at least the teacher and student are in the list
        participants = self.driver.find_elements(By.CSS_SELECTOR, "#participants-list .participant-item")
        self.assertGreaterEqual(len(participants), 2)
        
    def test_network_status(self):
        """Test network status indicator"""
        # Join a session
        self.test_join_session()
        
        # Verify network status indicator is present
        network_status = self.driver.find_element(By.ID, "network-status")
        self.assertIsNotNone(network_status)
        
        # Verify initial status is not "Offline"
        self.assertNotEqual(network_status.text, "Offline")
        
    def test_leave_session(self):
        """Test leaving a session"""
        # Join a session
        self.test_join_session()
        
        # Leave the session
        self.driver.find_element(By.ID, "leave-session-btn").click()
        
        # Verify redirected to dashboard
        self.wait.until(EC.presence_of_element_located((By.ID, "student-dashboard")))
        
if __name__ == "__main__":
    unittest.main()
"""
Email Service for SMTP Notifications
Handles sending welcome emails, notifications, and other email communications.
"""

import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
import os
import logging
from typing import Optional, List, Dict, Any
from datetime import datetime

class EmailService:
    def __init__(self):
        """Initialize email service with SMTP configuration"""
        self.smtp_host = os.environ.get('SMTP_HOST', 'smtp.gmail.com')
        self.smtp_port = int(os.environ.get('SMTP_PORT', '587'))
        self.smtp_username = os.environ.get('SMTP_USERNAME')
        self.smtp_password = os.environ.get('SMTP_PASSWORD')
        self.smtp_use_tls = os.environ.get('SMTP_USE_TLS', 'true').lower() == 'true'
        self.from_email = os.environ.get('FROM_EMAIL', self.smtp_username)
        self.from_name = os.environ.get('FROM_NAME', 'DigiKul Educational Platform')
        
        # Setup logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
        # Validate configuration
        if not self.smtp_username or not self.smtp_password:
            self.logger.warning("SMTP credentials not configured. Email notifications will be disabled.")
    
    def send_email(self, to_email: str, subject: str, html_content: str, 
                   text_content: Optional[str] = None, attachments: Optional[List[str]] = None) -> bool:
        """
        Send an email using SMTP
        
        Args:
            to_email: Recipient email address
            subject: Email subject
            html_content: HTML content of the email
            text_content: Plain text content (optional)
            attachments: List of file paths to attach (optional)
            
        Returns:
            bool: True if email was sent successfully, False otherwise
        """
        if not self.smtp_username or not self.smtp_password:
            self.logger.error("SMTP not configured. Cannot send email.")
            return False
        
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['From'] = f"{self.from_name} <{self.from_email}>"
            msg['To'] = to_email
            msg['Subject'] = subject
            
            # Add text content if provided
            if text_content:
                text_part = MIMEText(text_content, 'plain')
                msg.attach(text_part)
            
            # Add HTML content
            html_part = MIMEText(html_content, 'html')
            msg.attach(html_part)
            
            # Add attachments if any
            if attachments:
                for file_path in attachments:
                    if os.path.isfile(file_path):
                        with open(file_path, "rb") as attachment:
                            part = MIMEBase('application', 'octet-stream')
                            part.set_payload(attachment.read())
                        
                        encoders.encode_base64(part)
                        part.add_header(
                            'Content-Disposition',
                            f'attachment; filename= {os.path.basename(file_path)}'
                        )
                        msg.attach(part)
            
            # Create SMTP session
            context = ssl.create_default_context()
            
            with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                if self.smtp_use_tls:
                    server.starttls(context=context)
                
                server.login(self.smtp_username, self.smtp_password)
                server.send_message(msg)
            
            self.logger.info(f"Email sent successfully to {to_email}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to send email to {to_email}: {str(e)}")
            return False
    
    def send_welcome_email(self, user_email: str, user_name: str, user_type: str, 
                          cohort_name: Optional[str] = None, cohort_code: Optional[str] = None) -> bool:
        """
        Send welcome email to newly registered users
        
        Args:
            user_email: User's email address
            user_name: User's name
            user_type: Type of user (student, teacher, admin)
            cohort_name: Name of the cohort they were added to (optional)
            cohort_code: Cohort code for students to join (optional)
            
        Returns:
            bool: True if email was sent successfully, False otherwise
        """
        subject = f"Welcome to DigiKul, {user_name}!"
        
        # Create HTML content based on user type
        if user_type == 'student':
            html_content = self._create_student_welcome_email(user_name, cohort_name, cohort_code)
        elif user_type == 'teacher':
            html_content = self._create_teacher_welcome_email(user_name, cohort_name)
        else:
            html_content = self._create_admin_welcome_email(user_name)
        
        return self.send_email(user_email, subject, html_content)
    
    def send_lecture_notification(self, user_email: str, user_name: str, lecture_title: str, 
                                 teacher_name: str, scheduled_time: str, cohort_name: Optional[str] = None) -> bool:
        """
        Send lecture notification email
        
        Args:
            user_email: User's email address
            user_name: User's name
            lecture_title: Title of the lecture
            teacher_name: Name of the teacher
            scheduled_time: When the lecture is scheduled
            cohort_name: Name of the cohort (optional)
            
        Returns:
            bool: True if email was sent successfully, False otherwise
        """
        subject = f"New Lecture: {lecture_title}"
        
        html_content = f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
                    <h1 style="margin: 0; font-size: 28px;">🎓 DigiKul</h1>
                    <p style="margin: 10px 0 0 0; opacity: 0.9;">Educational Platform</p>
                </div>
                
                <div style="background: white; padding: 30px; border: 1px solid #e0e0e0; border-top: none;">
                    <h2 style="color: #333; margin-bottom: 20px;">New Lecture Scheduled</h2>
                    
                    <p>Hello {user_name},</p>
                    
                    <p>A new lecture has been scheduled for you:</p>
                    
                    <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3 style="color: #667eea; margin-top: 0;">{lecture_title}</h3>
                        <p><strong>Teacher:</strong> {teacher_name}</p>
                        <p><strong>Scheduled Time:</strong> {scheduled_time}</p>
                        {f'<p><strong>Cohort:</strong> {cohort_name}</p>' if cohort_name else ''}
                    </div>
                    
                    <p>Please log in to your DigiKul account to view more details and prepare for the lecture.</p>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="#" style="background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Access DigiKul</a>
                    </div>
                    
                    <p style="color: #666; font-size: 14px; margin-top: 30px;">
                        If you have any questions, please contact your teacher or administrator.
                    </p>
                </div>
                
                <div style="background: #f8f9fa; padding: 20px; border-radius: 0 0 10px 10px; text-align: center; color: #666; font-size: 12px;">
                    <p>© 2024 DigiKul Educational Platform. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        return self.send_email(user_email, subject, html_content)
    
    def send_quiz_notification(self, user_email: str, user_name: str, quiz_title: str, 
                              teacher_name: str, cohort_name: Optional[str] = None) -> bool:
        """
        Send quiz notification email
        
        Args:
            user_email: User's email address
            user_name: User's name
            quiz_title: Title of the quiz
            teacher_name: Name of the teacher
            cohort_name: Name of the cohort (optional)
            
        Returns:
            bool: True if email was sent successfully, False otherwise
        """
        subject = f"New Quiz Available: {quiz_title}"
        
        html_content = f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
                    <h1 style="margin: 0; font-size: 28px;">🎓 DigiKul</h1>
                    <p style="margin: 10px 0 0 0; opacity: 0.9;">Educational Platform</p>
                </div>
                
                <div style="background: white; padding: 30px; border: 1px solid #e0e0e0; border-top: none;">
                    <h2 style="color: #333; margin-bottom: 20px;">New Quiz Available</h2>
                    
                    <p>Hello {user_name},</p>
                    
                    <p>A new quiz has been made available for you:</p>
                    
                    <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3 style="color: #667eea; margin-top: 0;">{quiz_title}</h3>
                        <p><strong>Teacher:</strong> {teacher_name}</p>
                        {f'<p><strong>Cohort:</strong> {cohort_name}</p>' if cohort_name else ''}
                    </div>
                    
                    <p>Please log in to your DigiKul account to take the quiz.</p>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="#" style="background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Take Quiz</a>
                    </div>
                    
                    <p style="color: #666; font-size: 14px; margin-top: 30px;">
                        Make sure to complete the quiz within the specified time limit.
                    </p>
                </div>
                
                <div style="background: #f8f9fa; padding: 20px; border-radius: 0 0 10px 10px; text-align: center; color: #666; font-size: 12px;">
                    <p>© 2024 DigiKul Educational Platform. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        return self.send_email(user_email, subject, html_content)
    
    def _create_student_welcome_email(self, user_name: str, cohort_name: Optional[str], cohort_code: Optional[str]) -> str:
        """Create HTML content for student welcome email"""
        return f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
                    <h1 style="margin: 0; font-size: 28px;">🎓 DigiKul</h1>
                    <p style="margin: 10px 0 0 0; opacity: 0.9;">Educational Platform</p>
                </div>
                
                <div style="background: white; padding: 30px; border: 1px solid #e0e0e0; border-top: none;">
                    <h2 style="color: #333; margin-bottom: 20px;">Welcome to DigiKul, {user_name}!</h2>
                    
                    <p>We're excited to have you join our educational community. Your account has been successfully created and you're now part of our digital learning platform.</p>
                    
                    {f'''
                    <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3 style="color: #667eea; margin-top: 0;">You've been added to a cohort!</h3>
                        <p><strong>Cohort:</strong> {cohort_name}</p>
                        {f'<p><strong>Cohort Code:</strong> <code style="background: #e9ecef; padding: 2px 6px; border-radius: 3px;">{cohort_code}</code></p>' if cohort_code else ''}
                    </div>
                    ''' if cohort_name else ''}
                    
                    <h3 style="color: #333;">What you can do:</h3>
                    <ul style="color: #666;">
                        <li>Join live lectures and interactive sessions</li>
                        <li>Access course materials and resources</li>
                        <li>Participate in quizzes and assessments</li>
                        <li>Engage in discussions with teachers and peers</li>
                        <li>Track your learning progress</li>
                    </ul>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="#" style="background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Get Started</a>
                    </div>
                    
                    <p style="color: #666; font-size: 14px; margin-top: 30px;">
                        If you have any questions or need assistance, please don't hesitate to contact your teacher or our support team.
                    </p>
                </div>
                
                <div style="background: #f8f9fa; padding: 20px; border-radius: 0 0 10px 10px; text-align: center; color: #666; font-size: 12px;">
                    <p>© 2024 DigiKul Educational Platform. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
    
    def _create_teacher_welcome_email(self, user_name: str, cohort_name: Optional[str]) -> str:
        """Create HTML content for teacher welcome email"""
        return f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
                    <h1 style="margin: 0; font-size: 28px;">🎓 DigiKul</h1>
                    <p style="margin: 10px 0 0 0; opacity: 0.9;">Educational Platform</p>
                </div>
                
                <div style="background: white; padding: 30px; border: 1px solid #e0e0e0; border-top: none;">
                    <h2 style="color: #333; margin-bottom: 20px;">Welcome to DigiKul, {user_name}!</h2>
                    
                    <p>Welcome to the DigiKul teaching community! Your account has been successfully created and you're now ready to start delivering exceptional educational experiences.</p>
                    
                    {f'''
                    <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3 style="color: #667eea; margin-top: 0;">You've been assigned to a cohort!</h3>
                        <p><strong>Cohort:</strong> {cohort_name}</p>
                    </div>
                    ''' if cohort_name else ''}
                    
                    <h3 style="color: #333;">Teaching features available:</h3>
                    <ul style="color: #666;">
                        <li>Create and schedule live lectures</li>
                        <li>Upload and manage course materials</li>
                        <li>Conduct interactive quizzes and polls</li>
                        <li>Monitor student progress and analytics</li>
                        <li>Engage with students through discussions</li>
                        <li>Access comprehensive teaching tools</li>
                    </ul>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="#" style="background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Start Teaching</a>
                    </div>
                    
                    <p style="color: #666; font-size: 14px; margin-top: 30px;">
                        Need help getting started? Check out our teacher resources or contact our support team.
                    </p>
                </div>
                
                <div style="background: #f8f9fa; padding: 20px; border-radius: 0 0 10px 10px; text-align: center; color: #666; font-size: 12px;">
                    <p>© 2024 DigiKul Educational Platform. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
    
    def _create_admin_welcome_email(self, user_name: str) -> str:
        """Create HTML content for admin welcome email"""
        return f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
                    <h1 style="margin: 0; font-size: 28px;">🎓 DigiKul</h1>
                    <p style="margin: 10px 0 0 0; opacity: 0.9;">Educational Platform</p>
                </div>
                
                <div style="background: white; padding: 30px; border: 1px solid #e0e0e0; border-top: none;">
                    <h2 style="color: #333; margin-bottom: 20px;">Welcome to DigiKul Admin Panel, {user_name}!</h2>
                    
                    <p>Welcome to the DigiKul administrative team! Your admin account has been successfully created with full system access.</p>
                    
                    <h3 style="color: #333;">Administrative features available:</h3>
                    <ul style="color: #666;">
                        <li>Manage institutions and user accounts</li>
                        <li>Create and assign cohorts to teachers</li>
                        <li>Monitor system performance and analytics</li>
                        <li>Manage user permissions and access levels</li>
                        <li>Oversee educational content and resources</li>
                        <li>Generate comprehensive reports</li>
                    </ul>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="#" style="background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Access Admin Panel</a>
                    </div>
                    
                    <p style="color: #666; font-size: 14px; margin-top: 30px;">
                        Use your admin privileges responsibly and ensure the platform's security and educational effectiveness.
                    </p>
                </div>
                
                <div style="background: #f8f9fa; padding: 20px; border-radius: 0 0 10px 10px; text-align: center; color: #666; font-size: 12px;">
                    <p>© 2024 DigiKul Educational Platform. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """


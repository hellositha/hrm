PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE departments (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      manager_id TEXT,
      budget REAL DEFAULT 0,
      color TEXT DEFAULT '#3b82f6'
    );
INSERT INTO departments VALUES('dept-1','ផ្នែកបច្ចេកវិទ្យា & វិស្វកម្ម (Engineering & Tech)','ការអភិវឌ្ឍប្រព័ន្ធកម្មវិធី ហេដ្ឋារចនាសម្ព័ន្ធ Cloud និងប្រព័ន្ធឆ្លាតវៃ AI។',NULL,450000.0,'#3b82f6');
INSERT INTO departments VALUES('dept-2','ផ្នែករចនា & ផលិតផល (Product & Design)','យុទ្ធសាស្ត្រផលិតផលឌីជីថល និងការរចនាបទពិសោធន៍អ្នកប្រើប្រាស់ UI/UX។',NULL,280000.0,'#8b5cf6');
INSERT INTO departments VALUES('dept-3','ផ្នែកទីផ្សារ & ប្រព័ន្ធផ្សព្វផ្សាយ (Marketing & PR)','ការកសាងម៉ាកយីហោ ទីផ្សារឌីជីថល និងការផ្សព្វផ្សាយជាសាធារណៈ។',NULL,210000.0,'#ec4899');
INSERT INTO departments VALUES('dept-4','ផ្នែកលក់ & អភិវឌ្ឍន៍អាជីវកម្ម (Sales & Enterprise)','ការគ្រប់គ្រងអតិថិជនសហគ្រាស និងការពង្រីកទីផ្សារក្នុងតំបន់។',NULL,380000.0,'#10b981');
INSERT INTO departments VALUES('dept-5','ផ្នែកធនធានមនុស្ស (Human Resource)','ការគ្រប់គ្រងបុគ្គលិក អត្ថប្រយោជន៍ ប.ស.ស និងការអភិវឌ្ឍទេពកោសល្យ។',NULL,190000.0,'#f59e0b');
INSERT INTO departments VALUES('dept-6','ផ្នែកគណនេយ្យ & ហិរញ្ញវត្ថុ (Finance & Legal)','ផែនការហិរញ្ញវត្ថុ ការទូទាត់ពន្ធ និងអនុលោមភាពច្បាប់នៅកម្ពុជា។',NULL,250000.0,'#6366f1');
INSERT INTO departments VALUES('dept-1790073927008','ថ្នាក់ដឹកនាំជាន់ខ្ពស់ (Top Management)','','EMP-2026-125',0.0,'#3b82f6');
INSERT INTO departments VALUES('dept-1790076843772','ផ្នែករដ្ឋបាល (Administration)','',NULL,0.0,'#6366f1');
CREATE TABLE attendance (
      id TEXT PRIMARY KEY,
      employee_id TEXT NOT NULL,
      date TEXT NOT NULL,
      clock_in TEXT,
      clock_out TEXT,
      status TEXT NOT NULL,
      work_hours REAL DEFAULT 0,
      notes TEXT,
      UNIQUE(employee_id, date)
    );
CREATE TABLE leave_requests (
      id TEXT PRIMARY KEY,
      employee_id TEXT NOT NULL,
      leave_type TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      days_count REAL NOT NULL,
      reason TEXT,
      status TEXT NOT NULL DEFAULT 'Pending',
      reviewer_id TEXT,
      reviewed_at TEXT,
      reviewer_comments TEXT,
      created_at TEXT NOT NULL
    , line_manager_id TEXT, line_manager_reviewed_at TEXT, line_manager_comments TEXT, admin_reviewer_id TEXT, admin_reviewed_at TEXT, admin_comments TEXT);
CREATE TABLE leave_balances (
      id TEXT PRIMARY KEY,
      employee_id TEXT NOT NULL UNIQUE,
      annual_total REAL DEFAULT 20,
      annual_used REAL DEFAULT 0,
      sick_total REAL DEFAULT 10,
      sick_used REAL DEFAULT 0,
      casual_total REAL DEFAULT 5,
      casual_used REAL DEFAULT 0
    );
INSERT INTO leave_balances VALUES('bal-EMP-2026-160','EMP-2026-160',20.0,0.0,10.0,0.0,5.0,0.0);
INSERT INTO leave_balances VALUES('bal-EMP-2026-125','EMP-2026-125',20.0,0.0,10.0,0.0,5.0,0.0);
INSERT INTO leave_balances VALUES('bal-EMP-2026-624','EMP-2026-624',20.0,0.0,10.0,0.0,5.0,0.0);
INSERT INTO leave_balances VALUES('bal-EMP-2026-387','EMP-2026-387',20.0,0.0,10.0,0.0,5.0,0.0);
CREATE TABLE payrolls (
      id TEXT PRIMARY KEY,
      employee_id TEXT NOT NULL,
      pay_period TEXT NOT NULL,
      payment_date TEXT NOT NULL,
      base_salary REAL NOT NULL,
      allowances REAL DEFAULT 0,
      bonuses REAL DEFAULT 0,
      tax_deduction REAL DEFAULT 0,
      insurance_deduction REAL DEFAULT 0,
      other_deductions REAL DEFAULT 0,
      net_salary REAL NOT NULL,
      status TEXT NOT NULL DEFAULT 'Paid',
      payment_method TEXT DEFAULT 'Direct Deposit',
      created_at TEXT NOT NULL
    );
CREATE TABLE job_postings (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      department_id TEXT NOT NULL,
      location TEXT NOT NULL,
      type TEXT NOT NULL,
      experience_level TEXT NOT NULL,
      salary_range TEXT NOT NULL,
      description TEXT,
      requirements TEXT,
      status TEXT NOT NULL DEFAULT 'Active',
      posted_date TEXT NOT NULL,
      applicants_count INTEGER DEFAULT 0
    );
CREATE TABLE job_candidates (
      id TEXT PRIMARY KEY,
      job_id TEXT NOT NULL,
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      phone TEXT,
      stage TEXT NOT NULL DEFAULT 'Applied',
      rating INTEGER DEFAULT 3,
      applied_date TEXT NOT NULL,
      notes TEXT
    );
CREATE TABLE announcements (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      author_id TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'General',
      pinned INTEGER DEFAULT 0,
      created_at TEXT NOT NULL
    );
CREATE TABLE performance_reviews (
      id TEXT PRIMARY KEY,
      employee_id TEXT NOT NULL,
      reviewer_id TEXT NOT NULL,
      review_period TEXT NOT NULL,
      rating REAL NOT NULL,
      goals_achievement REAL NOT NULL,
      strengths TEXT,
      areas_for_growth TEXT,
      status TEXT NOT NULL DEFAULT 'Completed',
      created_at TEXT NOT NULL
    );
CREATE TABLE system_meta (
      key TEXT PRIMARY KEY,
      value TEXT
    );
INSERT INTO system_meta VALUES('initialized','true');
INSERT INTO system_meta VALUES('company_settings','{"name":"Hestra (Cambodia) Co.,Ltd","address":"FQPP+JC6, Phnom Penh, Cambodia","currency":"USD ($) & KHR (៛)","workHours":"8.0","timezone":"Asia/Phnom_Penh (GMT+7)","fiscalYearStart":"January 1st"}');
INSERT INTO system_meta VALUES('company_name','Hestra (Cambodia) Co.,Ltd');
CREATE TABLE IF NOT EXISTS "employees" (
      id TEXT PRIMARY KEY,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      email TEXT UNIQUE,
      phone TEXT,
      role TEXT NOT NULL,
      department_id TEXT NOT NULL,
      employment_type TEXT NOT NULL,
      employee_type TEXT DEFAULT 'បុគ្គលិកពេញសិទ្ធិ (Regular / Permanent)',
      status TEXT NOT NULL,
      salary REAL NOT NULL,
      join_date TEXT NOT NULL,
      manager_id TEXT,
      avatar TEXT,
      location TEXT,
      bio TEXT,
      emergency_contact_name TEXT,
      emergency_contact_phone TEXT,
      gender TEXT DEFAULT 'ប្រុស (Male)',
      dob TEXT,
      nationality TEXT DEFAULT 'កម្ពុជា (Cambodian)',
      marital_status TEXT DEFAULT 'នៅលីវ (Single)',
      national_id TEXT,
      current_address TEXT,
      province_city TEXT DEFAULT 'រាជធានីភ្នំពេញ (Phnom Penh)',
      district TEXT,
      commune_sangkat TEXT,
      village TEXT,
      contract_type TEXT DEFAULT 'UDC (មិនកំណត់ថិរវេលា)',
      contract_start TEXT,
      contract_end TEXT,
      work_location TEXT DEFAULT 'ការិយាល័យកណ្តាល (Head Office)',
      salary_currency TEXT DEFAULT 'USD ($)',
      salary_frequency TEXT DEFAULT 'ប្រចាំខែ (Monthly)',
      bank_name TEXT DEFAULT 'ABA Bank',
      bank_account_name TEXT,
      bank_account_number TEXT,
      nssf_member TEXT DEFAULT 'មាន (Yes)',
      nssf_number TEXT,
      nssf_reg_date TEXT,
      emergency_contact_relationship TEXT,
      emergency_contact_address TEXT,
      doc_national_id TEXT,
      doc_passport TEXT,
      doc_contract TEXT,
      doc_others TEXT,
      created_at TEXT NOT NULL
    , transport_allowance REAL DEFAULT 0, meal_allowance REAL DEFAULT 0, housing_allowance REAL DEFAULT 0, attendance_allowance REAL DEFAULT 0, seniority_bonus REAL DEFAULT 0, pay_grade TEXT DEFAULT 'Grade 2', last_salary_review TEXT);
INSERT INTO employees VALUES('EMP-2026-160','admin','Sarath Te',NULL,'077882285','HR Admin','dept-5','ពេញម៉ោង (Full-Time)','បុគ្គលិកពេញសិទ្ធិ (Regular / Permanent)','Active',1200.0,'2026-09-21',NULL,'/avatars/khmer_male_1.jpg','រាជធានីភ្នំពេញ (Phnom Penh)','','','','ប្រុស (Male)','1998-05-15','កម្ពុជា (Cambodian)','នៅលីវ (Single)','','','រាជធានីភ្នំពេញ (Phnom Penh)','','','','UDC (មិនកំណត់ថិរវេលា)','2026-09-21','','ការិយាល័យកណ្តាល (Head Office)','USD ($)','ប្រចាំខែ (Monthly)','ABA Bank (ធនាគារ អេ ប៊ី អេ)','admin HR','','មាន (Yes)','','2026-09-21','ប្តី/ប្រពន្ធ (Spouse)','','','','','','2026-09-21T17:14:41.814Z',0.0,0.0,0.0,0.0,0.0,'Grade 2',NULL);
INSERT INTO employees VALUES('EMP-2026-125','CEO','CEO',NULL,'','CEO','dept-1790073927008','ពេញម៉ោង (Full-Time)','បុគ្គលិកពេញសិទ្ធិ (Regular / Permanent)','Active',500000.0,'2026-09-21','EMP-2026-611','/avatars/khmer_male_1.jpg','រាជធានីភ្នំពេញ (Phnom Penh)','','','','ប្រុស (Male)','1998-05-15','កម្ពុជា (Cambodian)','នៅលីវ (Single)','','','រាជធានីភ្នំពេញ (Phnom Penh)','','','','UDC (មិនកំណត់ថិរវេលា)','2026-09-21','','ការិយាល័យកណ្តាល (Head Office)','USD ($)','ប្រចាំខែ (Monthly)','ABA Bank (ធនាគារ អេ ប៊ី អេ)','CEO','','មាន (Yes)','','2026-09-21','ប្តី/ប្រពន្ធ (Spouse)','','','','','','2026-09-21T17:57:27.978Z',0.0,0.0,0.0,0.0,0.0,'Grade 2',NULL);
INSERT INTO employees VALUES('EMP-2026-624','Vichet','Dy',NULL,'012532343','Recruiter','dept-1790076843772','ពេញម៉ោង (Full-Time)','បុគ្គលិកពេញសិទ្ធិ (Regular / Permanent)','Active',750.0,'2026-09-22','EMP-2026-125','','រាជធានីភ្នំពេញ (Phnom Penh)','','','','ប្រុស (Male)','2000-02-01','កម្ពុជា (Cambodian)','នៅលីវ (Single)','','','រាជធានីភ្នំពេញ (Phnom Penh)','','','','FDC (កំណត់ថិរវេលា)','2026-09-22','','ការិយាល័យកណ្តាល (Head Office)','USD ($)','ប្រចាំខែ (Monthly)','ABA Bank','Vichet Dy','001 889 231','មាន (Yes)','','2026-09-22','ប្តី/ប្រពន្ធ (Spouse)','','','','','','2026-09-22T10:54:15.107Z',30.0,20.0,0.0,0.0,0.0,'Grade 2','2026-09-22');
INSERT INTO employees VALUES('EMP-2026-387','Sitha','Sim',NULL,'+855 77882285','IT Support Officer','dept-1','ពេញម៉ោង (Full-Time)','បុគ្គលិកពេញសិទ្ធិ (Regular / Permanent)','Active',50.0,'2026-09-23','EMP-2026-125','data:image/jpeg;base64,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','រាជធានីភ្នំពេញ (Phnom Penh)','','','','ប្រុស (Male)','1981-01-01','កម្ពុជា (Cambodian)','រៀបការរួច (Married)','','','រាជធានីភ្នំពេញ (Phnom Penh)','','','','UDC (មិនកំណត់ថិរវេលា)','2026-09-23','','ការិយាល័យកណ្តាល (Head Office)','USD ($)','ប្រចាំខែ (Monthly)','ABA Bank (ធនាគារ អេ ប៊ី អេ)','Sitha Sim','','មាន (Yes)','','2026-10-01','ប្តី/ប្រពន្ធ (Spouse)','','','','','','2026-09-23T09:17:00.964Z',15.0,65.0,0.0,20.0,0.0,'Level 3 - Officer',NULL);
CREATE TABLE IF NOT EXISTS "users" (
      id TEXT PRIMARY KEY,
      username TEXT,
      name TEXT NOT NULL,
      email TEXT UNIQUE,
      role TEXT NOT NULL DEFAULT 'Employee',
      status TEXT NOT NULL DEFAULT 'Active',
      employee_id TEXT,
      department_name TEXT,
      avatar TEXT,
      two_factor_enabled INTEGER DEFAULT 0,
      permissions TEXT,
      password TEXT DEFAULT 'hestra123',
      last_login TEXT,
      created_at TEXT NOT NULL
    );
INSERT INTO users VALUES('usr-881815','admin','admin Sarath Te',NULL,'Admin','Active','EMP-2026-160','ផ្នែកធនធានមនុស្ស (Human Resource)','/avatars/khmer_male_1.jpg',0,'self_service,clock_in,request_leave,view_payslips,approve_leaves,manage_team_attendance,evaluate_performance,manage_payroll,manage_nssf,manage_employees,manage_users,system_settings,view_analytics','hestra123','2026-09-23 09:58 AM','2026-09-21');
INSERT INTO users VALUES('usr-447978','ceo','CEO Mr.',NULL,'Admin','Active','EMP-2026-125','ថ្នាក់ដឹកនាំជាន់ខ្ពស់ (Top Management)','/avatars/khmer_male_1.jpg',0,'self_service,clock_in,request_leave,view_payslips,approve_leaves,manage_team_attendance,evaluate_performance,manage_payroll,manage_nssf,manage_employees,manage_users,system_settings,view_analytics','hestra123','Just now','2026-09-21');
INSERT INTO users VALUES('usr-455108','vichet','Vichet Dy',NULL,'Employee','Active','EMP-2026-624','ផ្នែករដ្ឋបាល (Administration)','',0,'self_service,clock_in,request_leave,view_payslips','hestra123','2026-09-23 02:48 PM','2026-09-22');
INSERT INTO users VALUES('usr-020965','sitha','Sitha Sim',NULL,'Admin','Active','EMP-2026-387','ផ្នែកបច្ចេកវិទ្យា & វិស្វកម្ម (Engineering & Tech)','data:image/jpeg;base64,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',0,'self_service,clock_in,request_leave,view_payslips,approve_leaves,manage_team_attendance,evaluate_performance,manage_payroll,manage_nssf,manage_employees,manage_users,system_settings,view_analytics','online?','2026-09-27 01:36 AM','2026-09-23');
CREATE TABLE duty_roster (
      id TEXT PRIMARY KEY,
      employee_id TEXT NOT NULL,
      date TEXT NOT NULL,
      shift_type TEXT NOT NULL,
      start_time TEXT,
      end_time TEXT,
      hours REAL DEFAULT 8.0,
      location TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      UNIQUE(employee_id, date)
    );
CREATE TABLE overtime_requests (
      id TEXT PRIMARY KEY,
      employee_id TEXT NOT NULL,
      date TEXT NOT NULL,
      start_time TEXT NOT NULL,
      end_time TEXT NOT NULL,
      hours REAL NOT NULL,
      ot_rate_type TEXT NOT NULL,
      multiplier REAL NOT NULL DEFAULT 1.5,
      hourly_rate REAL DEFAULT 0,
      estimated_pay REAL DEFAULT 0,
      reason TEXT NOT NULL,
      project_name TEXT,
      status TEXT NOT NULL DEFAULT 'Pending Manager',
      line_manager_id TEXT,
      line_manager_reviewed_at TEXT,
      line_manager_comments TEXT,
      admin_reviewer_id TEXT,
      admin_reviewed_at TEXT,
      admin_comments TEXT,
      created_at TEXT NOT NULL
    );
CREATE TABLE salary_adjustments (
  id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  previous_salary REAL NOT NULL,
  new_salary REAL NOT NULL,
  increase_amount REAL NOT NULL,
  increase_percentage REAL NOT NULL,
  effective_date TEXT NOT NULL,
  adjustment_type TEXT NOT NULL,
  currency TEXT DEFAULT 'USD ($)',
  reason TEXT,
  approved_by TEXT,
  created_at TEXT NOT NULL
);
INSERT INTO salary_adjustments VALUES('adj-1790086544094-8h0w','EMP-2026-624',450.0,500.0,50.0,11.1099999999999994,'2026-10-01','Probation Confirmation','USD ($)','Successfully passed probation period with outstanding recruiting metrics','admin HR','2026-09-22T14:15:44.095Z');
INSERT INTO salary_adjustments VALUES('adj-1790088560140','EMP-2026-624',500.0,750.0,250.0,50.0,'2026-09-22','Staff Portal Request (Top Management Approved)','USD ($)','Outstanding annual delivery of core HR platform and payroll modernization.','CEO Executive','2026-09-22T14:49:20.139Z');
CREATE TABLE approval_requests (
  id TEXT PRIMARY KEY,
  request_number TEXT NOT NULL,
  employee_id TEXT NOT NULL,
  request_type TEXT NOT NULL,
  item_name TEXT NOT NULL,
  item_category TEXT NOT NULL,
  requires_top_management INTEGER NOT NULL DEFAULT 0,
  current_salary REAL DEFAULT 0,
  proposed_salary REAL DEFAULT 0,
  estimated_cost REAL DEFAULT 0,
  quantity INTEGER DEFAULT 1,
  urgency TEXT DEFAULT 'Medium',
  reason TEXT NOT NULL,
  specifications TEXT,
  status TEXT NOT NULL DEFAULT 'Pending Line Manager',
  line_manager_id TEXT,
  line_manager_name TEXT,
  line_manager_status TEXT DEFAULT 'Pending',
  line_manager_reviewed_at TEXT,
  line_manager_comments TEXT,
  hr_reviewer_id TEXT,
  hr_reviewer_name TEXT,
  hr_status TEXT DEFAULT 'Pending',
  hr_reviewed_at TEXT,
  hr_comments TEXT,
  top_management_id TEXT,
  top_management_name TEXT,
  top_management_status TEXT DEFAULT 'Pending',
  top_management_reviewed_at TEXT,
  top_management_comments TEXT,
  rejected_by_stage TEXT,
  rejection_reason TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
INSERT INTO approval_requests VALUES('req-1790088537458','REQ-2026-001','EMP-2026-624','Material / Equipment','MacBook Pro 16" M3 Max','high_value_asset',1,500.0,0.0,2499.0,1,'High','Required for heavy software engineering compilation and local microservice testbeds.','Apple M3 Max, 36GB RAM, 1TB SSD Space Black','Pending HR','EMP-2026-160','admin HR','Approved','2026-09-22T15:30:23.094Z','Approved by Line Manager. Forwarded to HR Department.',NULL,NULL,'Pending',NULL,NULL,NULL,NULL,'Pending',NULL,NULL,NULL,NULL,'2026-09-22T14:48:57.458Z','2026-09-22T15:30:23.094Z');
INSERT INTO approval_requests VALUES('req-1790088539684','REQ-2026-002','EMP-2026-624','Material / Equipment','Ergonomic Office Chair & Lumbar Support','standard_material',0,500.0,0.0,120.0,1,'Normal','Replacement for worn-out desk chair to improve ergonomic posture.','Mesh breathable backrest, adjustable armrests','Approved','usr-447978','Line Manager','Approved','2026-09-22T14:49:03.708Z','Approved. Needs ergonomic chair for posture.','usr-881815','admin HR','Approved','2026-09-22T14:49:05.474Z','Procurement approved. Item in stock at warehouse.',NULL,NULL,'N/A',NULL,NULL,NULL,NULL,'2026-09-22T14:48:59.684Z','2026-09-22T14:49:05.474Z');
INSERT INTO approval_requests VALUES('req-1790088541757','REQ-2026-003','EMP-2026-624','Salary Increase','Senior Software Engineer Merit Salary Increase','salary_increase',1,500.0,750.0,0.0,1,'Normal','Outstanding annual delivery of core HR platform and payroll modernization.','Base salary adjustment from $500 to $750/mo','Approved','usr-447978','Line Manager','Approved','2026-09-22T14:49:09.476Z','Agreed and supported based on strong engineering KPIs.','usr-881815','admin HR','Approved','2026-09-22T14:49:13.432Z','HR verified compensation benchmarking and budget ceiling. Forwarded for CEO executive authorization.','usr-447978','CEO Executive','Approved','2026-09-22T14:49:20.139Z','Final authorization granted. Well-deserved merit adjustment.',NULL,NULL,'2026-09-22T14:49:01.757Z','2026-09-22T14:49:20.139Z');
INSERT INTO approval_requests VALUES('req-1790173149899','REQ-2026-004','EMP-2026-624','Material / Equipment','Ergonomic Office Chair & Lumbar Support','standard_material',0,750.0,0.0,180.0,1,'Medium','Replacement chair for staff workstation ergonomics','[Office Material] High-back breathable mesh ergonomic chair','Pending HR','EMP-2026-387','Sitha Sim','Approved','2026-09-23T14:40:38.886Z','Approved by Line Manager. Forwarded to HR Department.',NULL,NULL,'Pending',NULL,NULL,NULL,NULL,'N/A',NULL,NULL,NULL,NULL,'2026-09-23T14:19:09.899Z','2026-09-23T14:40:38.886Z');
INSERT INTO approval_requests VALUES('req-1790173153078','REQ-2026-005','EMP-2026-624','Material / Equipment','Laptop (Workstation / Pro)','high_value_asset',1,750.0,0.0,1200.0,1,'High','Senior engineer device upgrade for mobile client deployments','[IT devices] High-performance laptop (Core i7 / 32GB RAM)','Pending HR','EMP-2026-387','Sitha Sim','Approved','2026-09-23T14:40:33.588Z','Approved by Line Manager. Forwarded to HR Department.',NULL,NULL,'Pending',NULL,NULL,NULL,NULL,'Pending',NULL,NULL,NULL,NULL,'2026-09-23T14:19:13.078Z','2026-09-23T14:40:33.588Z');
CREATE TABLE notifications (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      role TEXT DEFAULT 'All',
      title TEXT NOT NULL,
      title_km TEXT,
      message TEXT,
      message_km TEXT,
      type TEXT NOT NULL,
      link TEXT NOT NULL DEFAULT '/',
      is_read INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    );
INSERT INTO notifications VALUES('notif-req-001',NULL,'Admin','New Material Request REQ-2026-001 awaiting HR review','សំណើទិញសម្ភារៈថ្មី REQ-2026-001 កំពុងរង់ចាំការពិនិត្យពី HR','MacBook Pro 16" M3 Max submitted by IT Department','សំណើ MacBook Pro 16" M3 Max បញ្ជូនដោយផ្នែកបច្ចេកវិទ្យា','request','/requests',0,'2026-09-28T07:15:57.046Z');
INSERT INTO notifications VALUES('notif-leave-001',NULL,'All','Leave request pending approval: Dy Vuthey','សំណើសុំច្បាប់រង់ចាំការអនុម័ត៖ ឌី វុទ្ធី','Annual leave request for 3 days starting next Monday','សំណើសុំច្បាប់ប្រចាំឆ្នាំរយៈពេល ៣ ថ្ងៃ ចាប់ពីថ្ងៃច័ន្ទក្រោយ','leave','/leaves',0,'2026-09-28T06:35:57.046Z');
INSERT INTO notifications VALUES('notif-rec-001',NULL,'Admin','Candidate reached Offer stage: Dy Vuthey','បេក្ខជនដល់វគ្គផ្តល់ការងារ៖ ឌី វុទ្ធី','Senior Full Stack Developer recruitment pipeline update','ការជ្រើសរើសបុគ្គលិកតំណែង Senior Full Stack Developer','recruitment','/recruitment',0,'2026-09-28T05:30:57.046Z');
INSERT INTO notifications VALUES('notif-pay-001',NULL,'Admin','Monthly payroll draft is ready for review','ព្រាងបញ្ជីប្រាក់បៀវត្សរ៍ប្រចាំខែត្រូវបានបង្កើតរួចរាល់','Review staff payroll, tax deductions, and NSSF contributions','ពិនិត្យបញ្ជីប្រាក់ខែបុគ្គលិក ពន្ធលើប្រាក់បៀវត្ស និងការបង់ភាគទាន ប.ស.ស','payroll','/payroll',1,'2026-09-28T01:30:57.046Z');
INSERT INTO notifications VALUES('notif-ann-001',NULL,'All','Company Announcement: Khmer New Year Holiday Notice','សេចក្តីជូនដំណឹងក្រុមហ៊ុន៖ ថ្ងៃឈប់សម្រាកបុណ្យចូលឆ្នាំថ្មីប្រពៃណីជាតិ','Office will be closed from April 13 to April 16','ការិយាល័យនឹងឈប់សម្រាកចាប់ពីថ្ងៃទី ១៣ ដល់ ថ្ងៃទី ១៦ ខែមេសា','announcement','/announcements',1,'2026-09-27T07:30:57.046Z');
CREATE INDEX idx_notifications_user_role ON notifications(user_id, role, is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
COMMIT;

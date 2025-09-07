# Admin Functionality Test Guide

## 🧪 Testing the Admin Features

### Prerequisites
1. App is running on device/emulator
2. Database is initialized (happens automatically on first run)
3. Admin user is created (automatic)

### Test Scenario 1: Admin Login
1. **Launch the app**
2. **Login Screen appears**
3. **Enter admin credentials:**
   - Username: `admin`
   - Password: `admin29`
4. **Expected Result:** Login successful, home page appears

### Test Scenario 2: Admin Tools Visibility
1. **Prerequisite:** Logged in as admin
2. **Navigate to home page**
3. **Look for Admin Tools section**
4. **Expected Result:** Orange-colored admin tools section visible with two buttons:
   - "Import/Update Model"
   - "Export Logs"

### Test Scenario 3: Admin Panel Access
1. **Click "Import/Update Model" button**
2. **Expected Result:** Admin panel opens with two tabs:
   - "Model Management"
   - "Export Logs"

### Test Scenario 4: Model Import
1. **In admin panel, click "Import Model"**
2. **Expected Result:** File picker opens
3. **Select a .tflite file** (if available)
4. **Expected Result:** 
   - File imported successfully
   - Success message shown
   - Model appears in available models list

### Test Scenario 5: Model Management
1. **View available models list**
2. **Expected Result:** 
   - Default model shown
   - Any imported models shown
   - Current active model highlighted
3. **Try switching models**
4. **Expected Result:** Confirmation dialog appears

### Test Scenario 6: Export Logs (Placeholder)
1. **Click on "Export Logs" tab**
2. **Click "Export Logs" button**
3. **Expected Result:** "Coming soon" message displayed

### Test Scenario 7: Regular User Experience
1. **Logout from admin account**
2. **Register/Login as regular user**
3. **Navigate to home page**
4. **Expected Result:** NO admin tools section visible

### Test Scenario 8: Model Persistence
1. **As admin, switch to a different model**
2. **Close and restart the app**
3. **Login as admin**
4. **Check current active model**
5. **Expected Result:** Selected model remains active

## 🐛 Troubleshooting

### Issue: Admin tools not visible
- **Check:** User logged in with correct admin credentials
- **Verify:** User role is 'admin' in database
- **Solution:** Logout and login again with admin credentials

### Issue: File picker not opening
- **Check:** Device permissions for file access
- **Verify:** File picker package properly installed
- **Solution:** Grant storage permissions if prompted

### Issue: Model import fails
- **Check:** File is valid .tflite format
- **Verify:** Sufficient storage space available
- **Solution:** Try with a different model file

### Issue: App crashes after model switch
- **Check:** Model file still exists and is not corrupted
- **Verify:** Model format is compatible
- **Solution:** App should auto-revert to default model

## 📊 Success Criteria

✅ **Admin Login:** Admin can login with default credentials  
✅ **UI Integration:** Admin tools visible only to admin users  
✅ **Model Import:** Can successfully import .tflite files  
✅ **Model Switching:** Can switch between different models  
✅ **Persistence:** Model selection persists across app restarts  
✅ **Fallback:** App handles missing models gracefully  
✅ **Security:** Regular users cannot access admin features  

## 🎯 Demo Flow

### Quick Demo (5 minutes)
1. **Start:** Launch app, show login screen
2. **Admin Login:** Login with admin credentials
3. **Show Admin Tools:** Point out orange admin section
4. **Open Admin Panel:** Click Import/Update Model
5. **Demonstrate UI:** Show both tabs and features
6. **Model List:** Show current model and available models
7. **Export Placeholder:** Show export logs placeholder
8. **Regular User:** Logout, login as regular user, show no admin tools

### Detailed Demo (10 minutes)
1. All steps from Quick Demo
2. **Import Model:** Actually import a model file (if available)
3. **Switch Models:** Demonstrate model switching
4. **Test Classification:** Run classification to verify model change
5. **Persistence Test:** Restart app, verify model selection
6. **Error Handling:** Show what happens with invalid files

This completes the comprehensive admin functionality implementation for the Abaca Fiber Classifier app!

//
// (c) 2013 Appirio, Inc.
//
// A Test class for IntranetCourseDetailControllerTest
//
// 24 Dec 2013     Sudhir Kr. Jagetiya       Original
//
// Modified By : Alka Taneja
// Modified Date : 14 July, 2014
// Case : 00088978
//
@isTest
private class IntranetCourseDetailControllerTest {
  static final String DEFAULT_LANGUAGE_RECORD_TYPE = 'Default Language';
  static final String ALTERNATE_LANGUAGE_RECORD_TYPE = 'Alternate Language';
  static final String RECORD_LANGUAGE_FRENCH = 'FRENCH'; 
  
  static final Integer BULK_RECORD_SIZE = 5;
  
  static testMethod void myUnitTest() {
     User user = IntranetTestUtility.createUser(Integer.valueOf(Math.random()) + 10, true);
     
     User user1 = IntranetTestUtility.createUser(Integer.valueOf(Math.random()) + 20, false);
     user1.ManagerId = user.Id;
     insert user1;
     
     System.runAs(user1) {
     
	     Test.startTest();
	     
	       IntranetCourseDetailController controllerObject = new IntranetCourseDetailController();
	       controllerObject.getCourseInfo();
	       
	       Curriculum__c curriculum = IntranetTestUtility.createCurriculum(DEFAULT_LANGUAGE_RECORD_TYPE, false);
	       curriculum.Allow_Self_Enroll__c = true;
	       insert curriculum;
	       
	       Module__c module = IntranetTestUtility.createModule(curriculum.Id, DEFAULT_LANGUAGE_RECORD_TYPE, true);
	       
	       Course__c course = IntranetTestUtility.createCourse(DEFAULT_LANGUAGE_RECORD_TYPE, false);
	       course.Region__c = 'United States';
	       course.Allow_Self_Enroll__c = true;
	       insert course;
	       
	       Course_Module__c courseModule = IntranetTestUtility.createCourseModule(course.Id, module.Id, '1', true);
	       
	       Course__c altCourse = IntranetTestUtility.createCourse(ALTERNATE_LANGUAGE_RECORD_TYPE, false);
	       altCourse.Parent__c = course.Id;
	       altCourse.Language__c = RECORD_LANGUAGE_FRENCH;
	       insert altCourse;
	       
	       Edgeforce_Training__c testTraining = new Edgeforce_Training__c(Name='Test Training');
	       insert testTraining;
	       
	       Edgeforce_Assessment__c assess = new Edgeforce_Assessment__c(Max_Set__c = 1,Training__c = testTraining.Id,Total_Required_Questions__c=0,Enforce_Time_Limit__c=true , Time_Limit__c=30, Status__c='Active', Passing_Grade__c=75, Name='TestAssessment');
	       insert assess;
	       
	       List<Edgeforce_Questions__c> questionList = new List<Edgeforce_Questions__c>();
         Edgeforce_Questions__c question1 = new Edgeforce_Questions__c(Title__c='Test true false',Set__c = '1',Question_Type__c = 'True/False', status__c = 'Active', Assessment__c = assess.Id); 
         questionList.add(question1);
         Edgeforce_Questions__c question2 = new Edgeforce_Questions__c(Title__c='Test Single Choice',Set__c = '1',Question_Type__c = 'Single Choice',status__c = 'Active', Assessment__c = assess.Id);                                                                                         
         questionList.add(question2);
         Edgeforce_Questions__c question3 = new Edgeforce_Questions__c(Title__c='Test Matching',Set__c = '1',Question_Type__c = 'Matching',status__c = 'Active', Assessment__c = assess.Id);                                                                                                                                     
         questionList.add(question3);
         Edgeforce_Questions__c question4 = new Edgeforce_Questions__c(Title__c='Test Multiple Choice',Set__c = '1',Question_Type__c = 'Multiple Choice (MC)',status__c = 'Active', Assessment__c = assess.Id);                                                                                                                                     
         questionList.add(question4);
         Edgeforce_Questions__c question5 = new Edgeforce_Questions__c(Title__c='Test Category Matching',Set__c = '1',Question_Type__c = 'Category Matching',status__c = 'Active', Assessment__c = assess.Id);                                                                                                                                     
         questionList.add(question5);
         insert questionList;
         
         
         assess.Total_Required_Questions__c = 5;
         update assess;
	       
	       List<Asset__c> assetList = new List<Asset__c>();
	       Asset__c assessment;
	       for(Integer index = 0; index <  BULK_RECORD_SIZE; index++) {
	        assetList.add(IntranetTestUtility.createAsset(course.Id, DEFAULT_LANGUAGE_RECORD_TYPE, false));
	        assessment = IntranetTestUtility.createAsset(course.Id, DEFAULT_LANGUAGE_RECORD_TYPE, false);
	        assessment.Asset_Type__c = 'Assessment';
	        assessment.Assessment__c = assess.Id;
	        assetList.add(assessment);
	       }
	       
	       insert assetList;
	       
	       Asset__c altAsset;
	       List<Asset__c> altAssetList = new List<Asset__c>();
	       for(Asset__c asset : assetList) {
	         altAsset = IntranetTestUtility.createAsset(null, ALTERNATE_LANGUAGE_RECORD_TYPE, false);
	         altAsset.Parent__c = asset.Id;
	         altAsset.Language__c = RECORD_LANGUAGE_FRENCH;
	         altAssetList.add(altAsset);
	       }
	       insert altAssetList;
	       
	       ApexPages.currentPage().getParameters().put('Id', course.Id);
	       controllerObject = new IntranetCourseDetailController();
	       controllerObject.getCourseInfo();
	       
	       List<Training_User__c> trainingUsers = [SELECT Id, Language__c, Region__c FROM Training_User__c WHERE User__c = :UserInfo.getUserId() LIMIT 1];
         if(trainingUsers.size() > 0) {
           trainingUsers.get(0).Language__c = RECORD_LANGUAGE_FRENCH;
           trainingUSers.get(0).Region__c = 'United States';
           update trainingUsers.get(0);
         }
         
         controllerObject.getCourseInfo();
	       controllerObject.enrollUser();
	       
	       course.Allow_Self_Enroll__c = false;
         update course;
	       controllerObject.getCourseInfo();  
	       controllerObject.enrollUser();
	       
	       List<Course_Progress__c> enrolledrecords = [SELECT Id FROM Course_Progress__c WHERE Course__c = :course.Id AND Training_User__r.User__c = :UserInfo.getUserId()];
	       system.assert(enrolledrecords.size() > 0);
	       
	       controllerObject.currentRecordIndex = 0;
	       controllerObject.isAssessment = false;
	       controllerObject.isPreAssessment = false;
	       controllerObject.updateAssetProgress();
	       
	       List<Asset_Progress__c> assetProgressList = [SELECT Id, Status__c FROM Asset_Progress__c WHERE Asset__c = :controllerObject.assetsList.get(0).asset.Id AND Training_User__r.User__c = :UserInfo.getUserId()];
	       system.assert(assetProgressList.size() > 0);
	       system.assertEquals('Complete', assetProgressList.get(0).Status__c);
	       
	       controllerObject.currentRecordIndex = 0;
         controllerObject.isAssessment = true;
         controllerObject.isPreAssessment = true;
         controllerObject.updateAssetProgress();
         assetProgressList = [SELECT Id, Status__c FROM Asset_Progress__c WHERE Asset__c = :controllerObject.assessmentList.get(0).asset.Id AND Training_User__r.User__c = :UserInfo.getUserId()];
         //system.assert(assetProgressList.size() > 0);
         //system.assertEquals('In Progress', assetProgressList.get(0).Status__c);
            
         controllerObject.setToMove('Next');
         controllerObject.goToNextPreviousCourse();
         
         controllerObject.setToMove('Previous');
         controllerObject.goToNextPreviousCourse();
         
         controllerObject.unEnrollUser();
	       
	     Test.stopTest(); 
     }
  }
}
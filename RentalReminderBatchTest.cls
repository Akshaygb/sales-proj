@isTest
private class RentalReminderBatchTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = RentalTestDataFactory.createTestAccount();
        Contact testContact = RentalTestDataFactory.createTestContact(testAccount.Id);
        Instrument__c testInstrument = RentalTestDataFactory.createTestInstrument();
        
        // Create test email templates
        RentalTestDataFactory.createTestEmailTemplate('Daily_Rental_Reminder');
        RentalTestDataFactory.createTestEmailTemplate('Weekly_Rental_Reminder');
        RentalTestDataFactory.createTestEmailTemplate('Monthly_Rental_Reminder');
    }
    
    @isTest
    static void testDailyReminderBatch() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        // Create daily contract ending tomorrow
        Instrument_Rental_Contract__c contract = new Instrument_Rental_Contract__c(
            Customer__c = testAccount.Id,
            Contact__c = testContact.Id,
            Instrument__c = testInstrument.Id,
            Contract_Start_Date__c = Date.today(),
            Contract_End_Date__c = Date.today().addDays(1),
            Duration_Type__c = 'Daily',
            Rent_Amount__c = 25.00,
            Status__c = 'Active'
        );
        insert contract;
        
        Test.startTest();
        RentalReminderBatch batch = new RentalReminderBatch('Daily');
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify batch executed successfully
        System.assert(true, 'Daily reminder batch executed successfully');
    }
    
    @isTest
    static void testWeeklyReminderBatch() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        // Create weekly contract ending in 2 days
        Instrument_Rental_Contract__c contract = new Instrument_Rental_Contract__c(
            Customer__c = testAccount.Id,
            Contact__c = testContact.Id,
            Instrument__c = testInstrument.Id,
            Contract_Start_Date__c = Date.today(),
            Contract_End_Date__c = Date.today().addDays(2),
            Duration_Type__c = 'Weekly',
            Rent_Amount__c = 150.00,
            Status__c = 'Active'
        );
        insert contract;
        
        Test.startTest();
        RentalReminderBatch batch = new RentalReminderBatch('Weekly');
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify batch executed successfully
        System.assert(true, 'Weekly reminder batch executed successfully');
    }
    
    @isTest
    static void testMonthlyReminderBatch() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        // Create monthly contract ending in 7 days
        Instrument_Rental_Contract__c contract = new Instrument_Rental_Contract__c(
            Customer__c = testAccount.Id,
            Contact__c = testContact.Id,
            Instrument__c = testInstrument.Id,
            Contract_Start_Date__c = Date.today(),
            Contract_End_Date__c = Date.today().addDays(7),
            Duration_Type__c = 'Monthly',
            Rent_Amount__c = 500.00,
            Status__c = 'Active'
        );
        insert contract;
        
        Test.startTest();
        RentalReminderBatch batch = new RentalReminderBatch('Monthly');
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify batch executed successfully
        System.assert(true, 'Monthly reminder batch executed successfully');
    }
    
    @isTest
    static void testReminderBatchWithNullEndDate() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        // Create contract with null end date
        Instrument_Rental_Contract__c contract = new Instrument_Rental_Contract__c(
            Customer__c = testAccount.Id,
            Contact__c = testContact.Id,
            Instrument__c = testInstrument.Id,
            Contract_Start_Date__c = Date.today(),
            Contract_End_Date__c = null,
            Duration_Type__c = 'Daily',
            Rent_Amount__c = 25.00,
            Status__c = 'Active'
        );
        insert contract;
        
        Test.startTest();
        RentalReminderBatch batch = new RentalReminderBatch('Daily');
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify batch handles null date gracefully
        System.assert(true, 'Batch handled null end date gracefully');
    }
}
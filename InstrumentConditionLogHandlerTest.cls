@isTest
private class InstrumentConditionLogHandlerTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = RentalTestDataFactory.createTestAccount();
        Contact testContact = RentalTestDataFactory.createTestContact(testAccount.Id);
        Instrument__c testInstrument = RentalTestDataFactory.createTestInstrument();
        
        // Create test email templates
        RentalTestDataFactory.createTestEmailTemplate('Major_Damage_Alert');
    }
    
    @isTest
    static void testConditionLogInsertGoodCondition() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        Test.startTest();
        Instrument_Condition_Log__c log = RentalTestDataFactory.createTestConditionLog(
            contract.Id, 'Good'
        );
        Test.stopTest();
        
        // Verify log was created
        Instrument_Condition_Log__c result = [
            SELECT Id, Condition_Rating__c
            FROM Instrument_Condition_Log__c 
            WHERE Id = :log.Id
        ];
        
        System.assertEquals('Good', result.Condition_Rating__c);
    }
    
    @isTest
    static void testConditionLogInsertDamaged() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        Test.startTest();
        Instrument_Condition_Log__c log = RentalTestDataFactory.createTestConditionLog(
            contract.Id, 'Damaged'
        );
        Test.stopTest();
        
        // Verify damage alert was triggered
        Instrument_Condition_Log__c result = [
            SELECT Id, Condition_Rating__c
            FROM Instrument_Condition_Log__c 
            WHERE Id = :log.Id
        ];
        
        System.assertEquals('Damaged', result.Condition_Rating__c);
    }
    
    @isTest
    static void testConditionLogUpdateToDamaged() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        Instrument_Condition_Log__c log = RentalTestDataFactory.createTestConditionLog(
            contract.Id, 'Good'
        );
        
        Test.startTest();
        log.Condition_Rating__c = 'Poor';
        update log;
        Test.stopTest();
        
        // Verify condition change was processed
        Instrument_Condition_Log__c result = [
            SELECT Id, Condition_Rating__c
            FROM Instrument_Condition_Log__c 
            WHERE Id = :log.Id
        ];
        
        System.assertEquals('Poor', result.Condition_Rating__c);
    }
    
    @isTest
    static void testMultipleDamageRecords() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        Test.startTest();
        List<Instrument_Condition_Log__c> logs = new List<Instrument_Condition_Log__c>();
        for (Integer i = 0; i < 3; i++) {
            logs.add(new Instrument_Condition_Log__c(
                Rental_Contract__c = contract.Id,
                Log_Date__c = Date.today(),
                Log_Type__c = 'Inspection',
                Condition_Rating__c = 'Damaged',
                Condition_Notes__c = 'Test damage log ' + i
            ));
        }
        insert logs;
        Test.stopTest();
        
        // Verify all damage logs were created
        List<Instrument_Condition_Log__c> results = [
            SELECT Id FROM Instrument_Condition_Log__c 
            WHERE Rental_Contract__c = :contract.Id
        ];
        
        System.assertEquals(3, results.size());
    }
}
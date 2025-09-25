@isTest
private class OverdueContractBatchTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = RentalTestDataFactory.createTestAccount();
        Contact testContact = RentalTestDataFactory.createTestContact(testAccount.Id);
        Instrument__c testInstrument = RentalTestDataFactory.createTestInstrument();
        
        // Create test email templates
        RentalTestDataFactory.createTestEmailTemplate('Overdue_Contract_Alert');
    }
    
    @isTest
    static void testOverdueBatch() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        // Create overdue contract
        Instrument_Rental_Contract__c contract = new Instrument_Rental_Contract__c(
            Customer__c = testAccount.Id,
            Contact__c = testContact.Id,
            Instrument__c = testInstrument.Id,
            Contract_Start_Date__c = Date.today().addDays(-10),
            Contract_End_Date__c = Date.today().addDays(-3),
            Duration_Type__c = 'Weekly',
            Rent_Amount__c = 150.00,
            Status__c = 'Active'
        );
        insert contract;
        
        Test.startTest();
        OverdueContractBatch batch = new OverdueContractBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify contract status was updated to overdue
        Instrument_Rental_Contract__c result = [
            SELECT Id, Status__c FROM Instrument_Rental_Contract__c WHERE Id = :contract.Id
        ];
        
        System.assertEquals('Overdue', result.Status__c);
    }
    
    @isTest
    static void testOverdueBatchMultipleContracts() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        List<Instrument_Rental_Contract__c> contracts = new List<Instrument_Rental_Contract__c>();
        for (Integer i = 0; i < 5; i++) {
            contracts.add(new Instrument_Rental_Contract__c(
                Customer__c = testAccount.Id,
                Contact__c = testContact.Id,
                Instrument__c = testInstrument.Id,
                Contract_Start_Date__c = Date.today().addDays(-10),
                Contract_End_Date__c = Date.today().addDays(-2),
                Duration_Type__c = 'Weekly',
                Rent_Amount__c = 150.00,
                Status__c = 'Active'
            ));
        }
        insert contracts;
        
        Test.startTest();
        OverdueContractBatch batch = new OverdueContractBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify all contracts were updated
        List<Instrument_Rental_Contract__c> results = [
            SELECT Id, Status__c 
            FROM Instrument_Rental_Contract__c 
            WHERE Id IN :contracts
        ];
        
        for (Instrument_Rental_Contract__c result : results) {
            System.assertEquals('Overdue', result.Status__c);
        }
    }
    
    @isTest
    static void testOverdueBatchNoOverdueContracts() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        // Create future contract (not overdue)
        Instrument_Rental_Contract__c contract = new Instrument_Rental_Contract__c(
            Customer__c = testAccount.Id,
            Contact__c = testContact.Id,
            Instrument__c = testInstrument.Id,
            Contract_Start_Date__c = Date.today(),
            Contract_End_Date__c = Date.today().addDays(7),
            Duration_Type__c = 'Weekly',
            Rent_Amount__c = 150.00,
            Status__c = 'Active'
        );
        insert contract;
        
        Test.startTest();
        OverdueContractBatch batch = new OverdueContractBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify contract status remains Active
        Instrument_Rental_Contract__c result = [
            SELECT Id, Status__c FROM Instrument_Rental_Contract__c WHERE Id = :contract.Id
        ];
        
        System.assertEquals('Active', result.Status__c);
    }
}
@isTest
public class RentalTestDataFactory {
    
    public static Account createTestAccount() {
        Account testAccount = new Account(
            Name = 'Test Music Store',
            Type = 'Customer - Direct'
        );
        insert testAccount;
        return testAccount;
    }
    
    public static Contact createTestContact(Id accountId) {
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            Phone = '123-456-7890',
            AccountId = accountId
        );
        insert testContact;
        return testContact;
    }
    
    public static Instrument__c createTestInstrument() {
        Instrument__c testInstrument = new Instrument__c(
            Name = 'Test Guitar',
            Type__c = 'Guitar',
            Brand__c = 'Fender',
            Model__c = 'Stratocaster',
            Serial_Number__c = 'TEST12345',
            Purchase_Price__c = 1500.00,
            Daily_Rent_Rate__c = 25.00,
            Weekly_Rent_Rate__c = 150.00,
            Monthly_Rent_Rate__c = 500.00,
            Status__c = 'Available',
            Condition__c = 'Excellent'
        );
        insert testInstrument;
        return testInstrument;
    }
    
    public static Instrument_Rental_Contract__c createTestContract(Id customerId, Id contactId, Id instrumentId) {
        return createTestContract(customerId, contactId, instrumentId, 'Draft');
    }
    
    public static Instrument_Rental_Contract__c createTestContract(Id customerId, Id contactId, Id instrumentId, String status) {
        Instrument_Rental_Contract__c contract = new Instrument_Rental_Contract__c(
            Customer__c = customerId,
            Contact__c = contactId,
            Instrument__c = instrumentId,
            Contract_Start_Date__c = Date.today(),
            Contract_End_Date__c = Date.today().addDays(7),
            Duration_Type__c = 'Weekly',
            Rent_Amount__c = 150.00,
            Deposit_Amount__c = 100.00,
            Daily_Penalty_Rate__c = 10.00,
            Status__c = status,
            Payment_Status__c = 'Pending'
        );
        insert contract;
        return contract;
    }
    
    public static Payment_Record__c createTestPayment(Id contractId, Decimal amount, String paymentType) {
        Payment_Record__c payment = new Payment_Record__c(
            Rental_Contract__c = contractId,
            Amount__c = amount,
            Payment_Date__c = Date.today(),
            Payment_Method__c = 'Credit Card',
            Payment_Type__c = paymentType,
            Transaction_Reference__c = 'TEST-' + System.currentTimeMillis()
        );
        insert payment;
        return payment;
    }
    
    public static Instrument_Condition_Log__c createTestConditionLog(Id contractId, String condition) {
        Instrument_Condition_Log__c log = new Instrument_Condition_Log__c(
            Rental_Contract__c = contractId,
            Log_Date__c = Date.today(),
            Log_Type__c = 'Inspection',
            Condition_Rating__c = condition,
            Condition_Notes__c = 'Test condition log entry'
        );
        insert log;
        return log;
    }
    
    public static EmailTemplate createTestEmailTemplate(String developerName) {
        EmailTemplate template = new EmailTemplate(
            DeveloperName = developerName,
            Name = developerName.replace('_', ' '),
            Subject = 'Test Subject - {!Instrument_Rental_Contract__c.Name}',
            Body = 'Test email body',
            HtmlValue = '<p>Test HTML email body</p>',
            TemplateType = 'custom',
            IsActive = true,
            FolderId = UserInfo.getUserId()
        );
        insert template;
        return template;
    }
}

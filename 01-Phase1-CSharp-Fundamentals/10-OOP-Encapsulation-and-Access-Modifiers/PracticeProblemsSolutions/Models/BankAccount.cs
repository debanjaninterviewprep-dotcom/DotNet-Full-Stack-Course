class BankAccount
{
    public readonly int AccountNumber;
    public readonly string AccountHolderName;
    private decimal _balance;
    private int _pin;
    private List<string> _transactionHistory;
    public readonly DateTime CreatedAt;
    public decimal Balance => _balance;

    public BankAccount(int accountNumber, string accountHolderName, decimal initialBalance, int pin)
    {
        AccountNumber = accountNumber;
        AccountHolderName = accountHolderName;
        _balance = initialBalance;
        _pin = pin;
        _transactionHistory = new List<string>();
        CreatedAt = DateTime.Now;
    }

    public void Deposit(decimal amount)
    {
        if (amount <= 0)
        {
            throw new ArgumentException("Deposit amount must be positive.");
        }
        _balance += amount;
        _transactionHistory.Add($"Deposited: {amount:C} on {DateTime.Now}");
    }

    public void Withdraw(decimal amount, int pin)
    {
        if (pin != _pin)
        {
            throw new UnauthorizedAccessException("Invalid PIN.");
        }
        if (amount <= 0)
        {
            throw new ArgumentException("Withdrawal amount must be positive.");
        }
        if (amount > _balance)
        {
            throw new InvalidOperationException("Insufficient funds.");
        }
        _balance -= amount;
        _transactionHistory.Add($"Withdrew: {amount:C} on {DateTime.Now}");
    }

    public void Transfer(BankAccount targetAccount, decimal amount, int pin)
    {
        if (pin != _pin)
        {
            throw new UnauthorizedAccessException("Invalid PIN.");
        }
        if (amount <= 0)
        {
            throw new ArgumentException("Transfer amount must be positive.");
        }
        if (amount > _balance)
        {
            throw new InvalidOperationException("Insufficient funds.");
        }
        _balance -= amount;
        targetAccount._balance += amount;
        _transactionHistory.Add($"Transferred: {amount:C} to Account {targetAccount.AccountNumber} on {DateTime.Now}");
        targetAccount._transactionHistory.Add($"Received: {amount:C} from Account {AccountNumber} on {DateTime.Now}");
    }

    public void GetStatement(int pin)
    {
        if (pin != _pin)
        {
            throw new UnauthorizedAccessException("Invalid PIN.");
        }
        Console.WriteLine($"Account Statement for {AccountHolderName} (Account Number: {AccountNumber}):");
        foreach (var transaction in _transactionHistory)
        {
            Console.WriteLine(transaction);
        }
        Console.WriteLine($"Current Balance: {_balance:C}");
    }

    public void ChangePin(int oldPin, int newPin)
    {
        if (oldPin != _pin)
        {
            throw new UnauthorizedAccessException("Invalid old PIN.");
        }
        if (newPin < 1000 || newPin > 9999)
        {
            throw new ArgumentException("PIN must be a 4-digit number.");
        }
        _pin = newPin;
    }
}
class UserProfile
{
    private readonly int _id;
    public string UserName { get; private set; }
    public string Email { get; private set; }
    private string _password;
    public readonly DateTime CreatedAt = DateTime.Now;

    public UserProfile(int id, string userName, string email, string password)
    {
        _id = id;
        UserName = userName;
        Email = email;
        Password = password; // Use the property to ensure validation
        Console.WriteLine($"UserProfile created {UserName} with ID {id} at {CreatedAt}");
    }

    public void ChangeUserName(string newUserName)
    {
        Console.WriteLine($"Changing username from {UserName} to {newUserName}");
        if (!string.IsNullOrWhiteSpace(newUserName))
        {
            UserName = newUserName;
        }
        else
        {
            throw new ArgumentException("Username cannot be empty.");
        }
    }

    public void ChangeEmail(string newEmail)
    {
        Console.WriteLine($"Changing email from {Email} to {newEmail}");
        if (IsValidEmail(newEmail))
        {
            Email = newEmail;
        }
        else
        {
            throw new ArgumentException("Invalid email format.");
        }
    }

    public string Password
    {
        get { return _password; }
        private set
        {
            if (IsValidPassword(value))
            {
                _password = value;
            }
            else
            {
                throw new ArgumentException("Password must be at least 8 characters long and contain at least one number.");
            }
        }
    }

    private bool IsValidPassword(string password)
    {
        if (string.IsNullOrWhiteSpace(password) || password.Length < 8)
        {
            return false;
        }

        bool hasNumber = false;
        foreach (char c in password)
        {
            if (char.IsDigit(c))
            {
                hasNumber = true;
                break;
            }
        }

        return hasNumber;
    }

    private bool IsValidEmail(string email)
    {
        try
        {
            var addr = new System.Net.Mail.MailAddress(email);
            return addr.Address == email;
        }
        catch
        {
            return false;
        }
    }
}
class MultiFunctionPrinter : IPrintable, IScanable, IFaxable, IEmailable
{
    public void Print()
    {
        Console.WriteLine("Printing document...");
    }

    public void Scan()
    {
        Console.WriteLine("Scanning document...");
    }

    public void Fax()
    {
        Console.WriteLine("Faxing document...");
    }

    public void SendEmail()
    {
        Console.WriteLine("Sending document via email...");
    }
}
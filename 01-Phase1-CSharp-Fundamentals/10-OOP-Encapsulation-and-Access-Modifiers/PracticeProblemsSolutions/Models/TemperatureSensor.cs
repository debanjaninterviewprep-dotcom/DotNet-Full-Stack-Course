class TemperatureSensor
{
    private List<double> _readings;
    internal readonly string Location;
    private int _maxCapacity = 100;
    private int Count => _readings.Count;
    internal List<double> IReadonlyReadings => _readings.AsReadOnly().ToList();
    public static int SensorCount { get; private set; } = 0;

    public TemperatureSensor(string location)
    {
        Location = location;
        _readings = new List<double>();
        SensorCount++;
    }

    internal void AddReading(double temp)
    {
        if(IsValidTemperature(temp))
        {
            if (_readings.Count < _maxCapacity)
            {
                _readings.Add(temp);
            }
            else
            {
                throw new InvalidOperationException("Maximum capacity reached. Cannot add more readings.");
            }
        }
        else
        {
            throw new ArgumentOutOfRangeException("Temperature reading is out of valid range (-50 to 150).");
        }
    }

    private bool IsValidTemperature(double temp)
    {
        return temp >= -50 && temp <= 60;
    }

    internal double GetAverageTemperature
    {
        get
        {
            if (_readings.Count == 0) return 0;
            return _readings.Average();
        }
    }

    internal double GetMaxTemperature
    {
        get
        {
            if (_readings.Count == 0) return 0;
            return _readings.Max();
        }
    }

    internal double GetMinTemperature
    {
        get
        {
            if (_readings.Count == 0) return 0;
            return _readings.Min();
        }
    }

    internal List<double> GetReadings()
    {
        return IReadonlyReadings;
    }

    internal void ClearReadings()
    {
        _readings.Clear();
    }

}
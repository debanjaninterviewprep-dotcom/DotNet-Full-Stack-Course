class Service
{
    public static void CountVehicleTypes(List<Vehicle> vehicles)
    {
        int cars = 0, motorcycles = 0;

        foreach (var v in vehicles)
        {
            if (v is Car) cars++;
            else if (v is Motorcycle) motorcycles++;
        }

        Console.WriteLine("Vehicle Count by Type:");
        Console.WriteLine($"  Cars: {cars}");
        Console.WriteLine($"  Motorcycles: {motorcycles}");
    }

    // 2️⃣ Pattern matching with is — Print car-specific info only for Cars
    public static void PrintCarDetailsUsingIs(List<Vehicle> vehicles)
    {
        Console.WriteLine("Car Details (using 'is' pattern):");

        foreach (var v in vehicles)
        {
            if (v is Car car)
            {
                Console.WriteLine(
                    $"  {car.Year} {car.Make} {car.Model} — {car.NumberOfDoors} doors");
            }
        }

        Console.WriteLine();
    }

    // 3️⃣ as keyword — Safely get Car model and handle non-Car cases
    public static void PrintCarModelUsingAs(List<Vehicle> vehicles)
    {
        Console.WriteLine("Car Payloads (using 'as'):");

        foreach (var v in vehicles)
        {
            Car? car = v as Car;

            if (car != null)
            {
                Console.WriteLine(
                    $"  {car.Make} : {car.Model}"); // Assuming you want to print the model here
            }
            else
            {
                Console.WriteLine(
                    $"  {v.Make} : N/A (not a car)");
            }
        }

        Console.WriteLine();
    }

    // 4️⃣ Switch pattern matching — Classify each vehicle
    public static void ClassifyVehiclesUsingSwitch(List<Vehicle> vehicles)
    {
        Console.WriteLine("Classification (switch pattern):");

        foreach (var v in vehicles)
        {
            string result = v switch
            {
                Car { NumberOfDoors: >= 4 } c =>
                    $"🚗 Family car ({c.NumberOfDoors} doors)",

                Car c =>
                    $"🚙 Compact car ({c.NumberOfDoors} doors)",

                Motorcycle { HasSidecar: true } =>
                    "🏍️ Motorcycle with sidecar",

                Motorcycle =>
                    "🏍️ Solo rider (no sidecar)",

                _ => "Unknown vehicle"
            };

            Console.WriteLine($"  {v.Make} {v.Model} → {result}");
        }

        Console.WriteLine();
    }

    // 5️⃣ Filtering — Cars with more than 2 doors
    public static void FilterCarsWithMoreThanTwoDoors(List<Vehicle> vehicles)
    {
        Console.WriteLine("Cars with more than 2 doors:");

        var cars = vehicles
            .OfType<Car>()
            .Where(c => c.NumberOfDoors > 2);

        foreach (var car in cars)
        {
            Console.WriteLine(
                $"  {car.Make} {car.Model} ({car.NumberOfDoors} doors)");
        }

        Console.WriteLine();
    }

    // Sample Data
    public static List<Vehicle> SeedVehicles() => new()
    {
        new Car("Toyota", "Camry", 2020, 120, 4),
        new Motorcycle("Harley-Davidson", "Street 750", 2019, 100, false),
        new Car("Volvo", "FH16", 2021, 40, 2),
        new Car("Honda", "Civic", 2018, 110, 2),
        new Motorcycle("Ducati", "Panigale V4", 2020, 200, false),
        new Car("Ford", "F-150", 2019, 30, 1),
        new Car("Tesla", "Model S", 2021, 150, 4),
        new Motorcycle("BMW", "R1250GS", 2021, 110, true),
        new Car("Mercedes-Benz", "Actros", 2020, 50, 3)
    };
}
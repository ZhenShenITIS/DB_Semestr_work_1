import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

public class SeedData {

    private static final String URL = "jdbc:postgresql://localhost:5434/autoservice";
    private static final String USER = System.getenv("POSTGRES_USER");
    private static final String PASSWORD = System.getenv("POSTGRES_PASSWORD"); // Или тот, что в .env


    private static final int COUNT_CUSTOMERS = 250_000;
    private static final int COUNT_CARS = 300_000;
    private static final int COUNT_ORDERS = 350_000;
    private static final int COUNT_TASKS = 400_000;


    private static final List<String> carVins = new ArrayList<>(COUNT_CARS);

    public static void main(String[] args) {


        long start = System.currentTimeMillis();
        try {
            Class.forName("org.postgresql.Driver");
            try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD)) {

                conn.setAutoCommit(false);

                System.out.println("Начало заливки данных...");

                seedDictionaries(conn);
                seedCustomers(conn);
                seedCars(conn);
                seedOrders(conn);
                seedTasks(conn);

                System.out.println("Все данные успешно залиты!");
                System.out.println("Время выполнения: " + (System.currentTimeMillis() - start) / 1000 + " сек.");

            } catch (SQLException e) {
                e.printStackTrace();
            }
        } catch (ClassNotFoundException e) {
    }


    private static void seedDictionaries(Connection conn) throws SQLException {
        System.out.println("--- Генерация справочников ---");


        try (PreparedStatement ps = conn.prepareStatement("INSERT INTO autoservice_schema.branch_office (address, phone_number) VALUES (?, ?) RETURNING id")) {
            for (int i = 1; i <= 5; i++) {
                ps.setString(1, "Branch Address " + i);
                ps.setString(2, "8-800-555-35-3" + i);
                ps.addBatch();
            }
            ps.executeBatch();
        }


        try (PreparedStatement ps = conn.prepareStatement("INSERT INTO autoservice_schema.box (id_branch_office, box_type) VALUES (?, ?)")) {
            for (int i = 1; i <= 20; i++) {
                ps.setInt(1, ThreadLocalRandom.current().nextInt(1, 6));
                ps.setString(2, i % 3 == 0 ? "Premium" : "Standard");
                ps.addBatch();
            }
            ps.executeBatch();
        }


        try (PreparedStatement ps = conn.prepareStatement("INSERT INTO autoservice_schema.worker (full_name, role, phone_number, id_branch_office) VALUES (?, ?, ?, ?)")) {
            String[] roles = {"Mechanic", "Manager", "Electrician"};
            for (int i = 1; i <= 50; i++) {
                ps.setString(1, "Worker Name " + i);
                ps.setString(2, roles[ThreadLocalRandom.current().nextInt(roles.length)]);
                ps.setString(3, "+790000000" + i);
                ps.setInt(4, ThreadLocalRandom.current().nextInt(1, 6));
                ps.addBatch();
            }
            ps.executeBatch();
        }
        conn.commit();
    }


    private static void seedCustomers(Connection conn) throws SQLException {
        System.out.println("--- Генерация Клиентов (" + COUNT_CUSTOMERS + ") ---");
        String sql = "INSERT INTO autoservice_schema.customer (full_name, phone_number, email, loyalty_tier, profile_data, tags) VALUES (?, ?, ?, ?, ?::jsonb, ?)";

        String[] tiers = {"Bronze", "Silver", "Gold", "Platinum"};
        String[] possibleTags = {"oil", "tires", "tuning", "washing", "repair", "engine"};

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 1; i <= COUNT_CUSTOMERS; i++) {
                ps.setString(1, "Customer " + i);
                ps.setString(2, "+7999" + String.format("%07d", i));


                ps.setString(3, "user" + i + "@example.com");

                int rand = ThreadLocalRandom.current().nextInt(100);
                String tier = "Bronze";
                if (rand > 98) tier = "Platinum";
                else if (rand > 90) tier = "Gold";
                else if (rand > 70) tier = "Silver";
                ps.setString(4, tier);


                String json = String.format("{\"age\": %d, \"source\": \"web\", \"registered\": true}",
                        ThreadLocalRandom.current().nextInt(18, 90));
                ps.setString(5, json);


                List<String> tags = new ArrayList<>();
                int tagCount = ThreadLocalRandom.current().nextInt(0, 4);
                for (int t = 0; t < tagCount; t++) {
                    tags.add(possibleTags[ThreadLocalRandom.current().nextInt(possibleTags.length)]);
                }
                ps.setArray(6, conn.createArrayOf("text", tags.toArray()));

                ps.addBatch();
                if (i % 5000 == 0) ps.executeBatch();
            }
            ps.executeBatch();
            conn.commit();
        }
    }


    private static void seedCars(Connection conn) throws SQLException {
        System.out.println("--- Генерация Машин (" + COUNT_CARS + ") ---");
        String sql = "INSERT INTO autoservice_schema.car (vin, model, plate_number, status, box_id, mileage, history_log) VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 1; i <= COUNT_CARS; i++) {

                String vin = "VIN" + String.format("%014d", i);
                carVins.add(vin);

                ps.setString(1, vin);
                ps.setString(2, "Model-" + ThreadLocalRandom.current().nextInt(1, 100));
                ps.setString(3, "X" + ThreadLocalRandom.current().nextInt(100, 999) + "XX");
                ps.setString(4, "Ready");
                ps.setInt(5, ThreadLocalRandom.current().nextInt(1, 21));


                ps.setInt(6, ThreadLocalRandom.current().nextInt(0, 300_000));

                ps.setString(7, "Car history log entry number " + i + ". Replaced oil, filters. Customer complained about noise.");

                ps.addBatch();
                if (i % 5000 == 0) ps.executeBatch();
            }
            ps.executeBatch();
            conn.commit();
        }
    }


    private static void seedOrders(Connection conn) throws SQLException {
        System.out.println("--- Генерация Заказов (" + COUNT_ORDERS + ") ---");
        String sql = "INSERT INTO autoservice_schema.\"order\" (customer_id, creation_date, description, discount_percent, scheduling_slot, manager_notes) VALUES (?, ?, ?, ?, ?::tsrange, ?)";


        int vipLimit = 1000;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 1; i <= COUNT_ORDERS; i++) {


                int customerId;
                if (ThreadLocalRandom.current().nextDouble() < 0.7) {

                    customerId = ThreadLocalRandom.current().nextInt(1, vipLimit + 1);
                } else {

                    customerId = ThreadLocalRandom.current().nextInt(vipLimit + 1, COUNT_CUSTOMERS + 1);
                }
                ps.setInt(1, customerId);


                LocalDateTime date = LocalDateTime.now().minusDays(ThreadLocalRandom.current().nextInt(0, 365));
                ps.setTimestamp(2, Timestamp.valueOf(date));
                ps.setString(3, "Order description " + i);

                if (ThreadLocalRandom.current().nextDouble() < 0.2) {
                    ps.setNull(4, Types.DECIMAL);
                } else {
                    ps.setDouble(4, ThreadLocalRandom.current().nextDouble(0, 25.0));
                }


                String tsRange = String.format("[%s, %s)",
                        date.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")),
                        date.plusHours(2).format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")));
                ps.setString(5, tsRange);

                ps.setString(6, "Manager notes for order " + i);

                ps.addBatch();
                if (i % 5000 == 0) ps.executeBatch();
            }
            ps.executeBatch();
            conn.commit();
        }
    }

    private static void seedTasks(Connection conn) throws SQLException {
        System.out.println("--- Генерация Задач (" + COUNT_TASKS + ") ---");
        String sql = "INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id, estimated_cost_range, warranty_period, difficulty_score) VALUES (?, ?, ?, ?, ?, ?::numrange, ?::daterange, ?)";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 1; i <= COUNT_TASKS; i++) {

                ps.setInt(1, ThreadLocalRandom.current().nextInt(1, COUNT_ORDERS + 1));
                ps.setDouble(2, ThreadLocalRandom.current().nextDouble(100, 5000));
                ps.setInt(3, ThreadLocalRandom.current().nextInt(1, 50));
                ps.setString(4, "Fix engine part " + i);


                ps.setString(5, carVins.get(ThreadLocalRandom.current().nextInt(carVins.size())));


                int costStart = ThreadLocalRandom.current().nextInt(100, 4000);
                ps.setString(6, String.format("[%d, %d)", costStart, costStart + 500));


                ps.setString(7, "[2024-01-01, 2025-01-01)");


                ps.setInt(8, ThreadLocalRandom.current().nextInt(1, 101));

                ps.addBatch();
                if (i % 5000 == 0) ps.executeBatch();
            }
            ps.executeBatch();
            conn.commit();
        }
    }
}

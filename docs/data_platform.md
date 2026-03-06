# Data Platform

## Scenario
Design the data platform for an online marketplace similar to Amazon or Etsy.
The platform supports customers browsing products, placing orders, and sellers fulfilling them.

## Requirements

1. **Users**

   - Users can register as **customers**, **sellers**, or both.
   - Each user has a unique ID, name, email, and registration date.

2. **Products**

   - Sellers can list multiple products.
   - Each product has a name, description, price, and category.
   - A product belongs to exactly one seller.

3. **Orders**

   - Customers can place multiple orders.
   - Each order has an order date, status, and total amount.
   - An order can contain **multiple products** with different quantities.

4. **Order Items**

   - Each product in an order has a quantity and price at the time of purchase.

5. **Payments**

   - Each order has one payment.
   - Payments include payment method, payment status, and payment timestamp.

## Entity Relationship Diagram

![Alt text](./marketplace_db.drawio.svg)




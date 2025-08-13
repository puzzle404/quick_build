# Overview
This Rails application is a marketplace for construction materials. It supports four main user flows:

1. **Buyers** – search, compare and purchase materials online.
2. **Sellers** – company representatives who manage a catalog of materials offered by their company.
3. **Constructors** – builders who can both purchase materials and manage construction projects in a dedicated dashboard.
4. **Admins** – owners of the platform with access to administrative features.

Authentication and registration are handled with Devise and must remain compatible with it. Users belong to one of the roles above and seller accounts are associated with a company. The system is designed to support multiple companies (multi‑tenant), each having many users that represent them.

Future features will expand project management for constructors and allow attaching additional roles to users as the platform grows.

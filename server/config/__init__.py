"""Package init — the MySQL driver shim lives here, and only here.

Django speaks to MySQL through `MySQLdb`, which is provided by `mysqlclient`, a
C extension needing a compiler and MySQL headers. Shared cPanel hosting usually
has neither. PyMySQL is pure Python and installs anywhere, and this line is what
lets Django find it under the name it expects.

It must run **before** Django touches the database, which is why it is in the
package `__init__` rather than in a settings module: settings are imported after
`django.setup()` has already begun resolving backends.

Harmless when PyMySQL is not installed — a PostgreSQL deployment simply skips it,
which keeps `docs/CONVENTIONS.md`'s stack the default rather than a special case.
"""

try:
    import pymysql
except ImportError:  # PostgreSQL deployment, or no database driver yet.
    pass
else:
    pymysql.install_as_MySQLdb()

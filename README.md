# Playground

This is just a playground.

It is possible to open the playground in eclipse 2021-03.\
Eclipse can be downloaded here: https://www.eclipse.org/downloads/packages/ \
Recommended package is "Eclipse IDE for Enterprise Java Developers"

The project can be build using maven 3.6.3 via e.g.\
`mvn install`

The project uses UUID Version 6 as JPA entity id:\
UUID Version 6 is not yet official but an ongoing proposal, for details see:\
https://github.com/uuid6/uuid6-ietf-draft

To use the project configure a postgresql database (postgresql version >= 10):\
Add a database: playground\
Add a database schema: uuid

To create the database and add a schema to it, the UI tool: pgAdmin 4 can be used:\
https://www.pgadmin.org/download/

Create the file: `/playground/src/main/java/hibernate.properties`\
And add the relevant properties.\
All properties that are defined in `hibernate.properties` have to be commented out in:\
`/playground/src/main/java/META-INF/persistence.xml` since those take precedence over\
the properties defined in `hibernate.properties`.

If you run postgresql on localhost:5432 and if the user postgres is used, then only:\
`hibernate.connection.password=`\
is required to be specified in the `hibernate.properties`.

To see some action go to:\
`/playground/src/main/java/com/github/stefanhh0/playground/uuid/Main.java`\
And chose 'Run as' -> 'Java Application' from the eclipse context menu.

Additionally added a git-setup.sh and some scripts in githooks that demonstrate how to achieve pre-commit formatting.
Pre-commit formatting might be useful for projects where the members use different Tools to edit the source code but
where a common source formatting is wanted.

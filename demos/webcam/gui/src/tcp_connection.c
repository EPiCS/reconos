///
/// \file  tcp_connection.c
/// Convenience functions for creating TCP/IP connections.
/// 
/// Provides functions for listening for TCP connections and connecting
/// to remote servers, as well as transferring of arbitrarily sized data.
///
/// Written for the ReconOS netimage tools to send and receive image
/// data to and from a ReconOS board. 
/// 
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       12.09.2007
//
// For detailed documentation of the functions, see the associated header
// file or the documentation.
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group 
//
// (C) Copyright University of Paderborn 2007. Permission to copy,
// use, modify, sell and distribute this software is granted provided
// this copyright notice appears in all copies. This software is
// provided "as is" without express or implied warranty, and with no
// claim as to its suitability for any purpose.
//
// -------------------------------------------------------------------------
// Major Changes:
// 
// 12.09.2007   Enno Luebbers   File created
// 

// INCLUDES ================================================================

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>
#include <assert.h>

#include "debug.h"
#include "tcp_connection.h"


// FUNCTION DEFINITIONS ====================================================

//
// Creates a TCP/IP server by binding to a socket and listening. The 
// returned data structure can be used to 'tcp_accept' incoming
// connections.
//
tcp_server *tcp_server_create( unsigned int port, unsigned int backlog )
{
    int n;
    tcp_server *s;

    DEBUG_ENTRY( "tcp_server_create()" )

        s = malloc( sizeof( tcp_server ) );
    if ( s == NULL ) {
        perror( "malloc" );
        DEBUG_EXIT( "tcp_server_create()" )
            return NULL;
    }

    s->sockfd = socket( AF_INET, SOCK_STREAM, 0 );
    if ( s->sockfd < 0 ) {
        perror( "socket" );
        free( s );
        DEBUG_EXIT( "tcp_server_create()" )
            return NULL;
    }
    bzero( ( char * ) &s->addr, sizeof( s->addr ) );
    s->addr.sin_family = AF_INET;
    s->addr.sin_addr.s_addr = INADDR_ANY;
    s->addr.sin_port = htons( port );
    if ( bind( s->sockfd, ( struct sockaddr * ) &s->addr,
               sizeof( s->addr ) ) < 0 ) {
        perror( "bind" );
        free( s );
        DEBUG_EXIT( "tcp_server_create()" )
            return NULL;
    }
    listen( s->sockfd, backlog );

    DEBUG_EXIT( "tcp_server_create()" )
        return s;
}


//
// Creates a TCP/IP connection by accepting an incoming connection.
// If there are no incoming connections (and the server wasn't created
// with a O_NONBLOCK flag), tcp_accept waits until a client connects.
// To multiplex, use 'select()'.
// The returned data structure can be used to 'tcp_send' and
// 'tcp_receive' data.
//
tcp_connection *tcp_accept( tcp_server * server )
{
    int clilen;
    tcp_connection *con;

    DEBUG_ENTRY( "tcp_accept()" )
        assert( server != NULL );

    con = malloc( sizeof( tcp_connection ) );
    if ( con == NULL ) {
        perror( "malloc" );
        DEBUG_EXIT( "tcp_accept()" )
            return NULL;
    }
    con->blocksize = INIT_BLOCKSIZE;

    clilen = sizeof( con->addr );
    con->sockfd = accept( server->sockfd,
                          ( struct sockaddr * ) &con->addr, &clilen );
    if ( con->sockfd < 0 ) {
        perror( "accept" );
        free( con );
        DEBUG_EXIT( "tcp_accept()" )
            return NULL;
    }

    DEBUG_PRINT( DEBUG_NOTE, "connection accepted" )
        DEBUG_EXIT( "tcp_accept()" )
        return con;
}


//
// Creates a TCP/IP connection by connecting to a remote host.
// The returned data structure can be used to 'tcp_send' and
// 'tcp_receive' data.
//
tcp_connection *tcp_connection_create( const char *address,
                                       unsigned int port )
{
    tcp_connection *con;
    struct hostent *server;

    DEBUG_ENTRY( "tcp_connection_create()" )
        assert( address != NULL );

    con = malloc( sizeof( tcp_connection ) );
    if ( con == NULL ) {
        perror( "malloc" );
        DEBUG_EXIT( "tcp_connection_create()" )
            return NULL;
    }
    con->blocksize = INIT_BLOCKSIZE;

    con->sockfd = socket( AF_INET, SOCK_STREAM, 0 );
    if ( con->sockfd < 0 ) {
        perror( "socket" );
        free( con );
        DEBUG_EXIT( "tcp_connection_create()" )
            return NULL;
    }
    server = gethostbyname( address );
    if ( server == NULL ) {
        fprintf( stderr, "gethostbyname: no such host\n" );
        free( con );
        DEBUG_EXIT( "tcp_connection_create()" )
            return NULL;
    }
    bzero( ( char * ) &con->addr, sizeof( con->addr ) );
    con->addr.sin_family = AF_INET;
    bcopy( ( char * ) server->h_addr,
           ( char * ) &con->addr.sin_addr.s_addr, server->h_length );
    con->addr.sin_port = htons( port );
    if ( connect
         ( con->sockfd, ( struct sockaddr * ) &con->addr,
           sizeof( con->addr ) ) < 0 ) {
        perror( "connect" );
        free( con );
        DEBUG_EXIT( "tcp_connection_create()" )
            return NULL;
    }

    DEBUG_PRINT( DEBUG_NOTE, "connection created" )
        DEBUG_EXIT( "tcp_connection_create()" )
        return con;
}


//
// Sends data over a tcp_connection.
//
int tcp_send( tcp_connection * con, unsigned char *buf, size_t len )
{
    int n, sent = 0;

    DEBUG_ENTRY( "tcp_send()" )
        assert( con != NULL );
    assert( buf != NULL );

    while ( sent < len ) {
        n = write( con->sockfd, &buf[sent],
                   MIN( len - sent, con->blocksize ) );
        //fprintf(stderr, "\npackage (len: %d) - %d", MIN(len-sent,con->blocksize), n);
        if ( n < 0 ) {
            perror( "write" );
            DEBUG_EXIT( "tcp_send()" )
                return n;
        }
//         printf("---> sent %6d of %6d bytes (%.2f %%)\n", sent, len, (float)(100*sent)/len);
        sent += n;
    }
    DEBUG_EXIT( "tcp_send()" )
        return sent;
}


//
// Receives data over a tcp_connection. Will block until data has been read.
//
int tcp_receive( tcp_connection * con, unsigned char *buf, size_t len )
{
    int n, recvd = 0;


    DEBUG_ENTRY( "tcp_receive()" )
        assert( con != NULL );
    assert( buf != NULL );

    bzero( buf, len );

    while ( recvd < len ) {
        n = read( con->sockfd, &buf[recvd],
                  MIN( len - recvd, con->blocksize ) );
        if ( n < 0 ) {
            perror( "read" );
            DEBUG_EXIT( "tcp_receive()" )
                return n;
        }
        if ( n == 0 ) {
            DEBUG_EXIT( "tcp_receive()" )
                return recvd;
        }
//         printf("---> received %6d of %6d bytes (%.2f %%)\n", recvd, len, (float)(100*recvd)/len);
        recvd += n;
    }
    DEBUG_EXIT( "tcp_receive()" )
        return recvd;
}


//
// Closes a TCP connection and frees the associated data structure.
//
void tcp_connection_destroy( tcp_connection * con )
{

    DEBUG_ENTRY( "tcp_connection_destroy()" )
        assert( con != NULL );
    close( con->sockfd );
    free( con );
    DEBUG_PRINT( DEBUG_NOTE, "connection destroyed" );
    DEBUG_EXIT( "tcp_connection_destroy()" )

}

//
// Closes a TCP listening socket and frees the associated data structure.
//
void tcp_server_destroy( tcp_server * s )
{

    DEBUG_ENTRY( "tcp_server_destroy()" )
        assert( s != NULL );
    close( s->sockfd );
    free( s );
    DEBUG_PRINT( DEBUG_NOTE, "server destroyed" );
    DEBUG_EXIT( "tcp_server_destroy()" )

}


///
/// Converts a error return value from getnameinfo() to a string.
///
/// \param      errval             the error value
///
/// \returns    a pointer to the corresponding string/
///
const char *eaistr( int errval )
{

    switch ( errval ) {
    case EAI_AGAIN:
        return "EAI_AGAIN";
    case EAI_BADFLAGS:
        return "EAI_BADFLAGS";
    case EAI_FAIL:
        return "EAI_FAIL";
    case EAI_FAMILY:
        return "EAI_FAMILY";
    case EAI_MEMORY:
        return "EAI_MEMORY";
    case EAI_NONAME:
        return "EAI_NONAME";
    case EAI_OVERFLOW:
        return "EAI_OVERFLOW";
    case EAI_SYSTEM:
        return "EAI_SYSTEM";
    default:
        return "UNKNOWN";
    }
}


//
// Retreives the fully qualified domain name (FQDN) of a internet host
// address given as a 'struct sockaddr_in', if available. If the hostname
// cannot be retrieved, the numeric IP address is returned instead.
//
// This code is adapted from openssh's "canonhost.c".
//
const char *sockaddr2hostname( struct sockaddr_in *from, char *name,
                               size_t namelen )
{

    int i, result;
    socklen_t fromlen;
    char ntop[NI_MAXHOST];

    DEBUG_ENTRY( "sockaddr2hostname()" )

        fromlen = sizeof( struct sockaddr_in );

    if ( result =
         getnameinfo( ( struct sockaddr * ) from, fromlen, ntop,
                      sizeof( ntop ), NULL, 0, NI_NUMERICHOST ) != 0 ) {
        fprintf( stderr,
                 "get_remote_hostname: getnameinfo NI_NUMERICHOST failed (%s)\n",
                 eaistr( result ) );
        DEBUG_EXIT( "sockaddr2hostname()" )
            return NULL;
    }

    /* Map the IP address to a host name. */
    if ( getnameinfo( ( struct sockaddr * ) from, fromlen, name, namelen,
                      NULL, 0, NI_NAMEREQD ) == 0 ) {
        /* Got host name. */
        name[namelen - 1] = '\0';
        /*
         * Convert it to all lowercase (which is expected by the rest
         * of this software).
         */
        for ( i = 0; name[i]; i++ )
            if ( isupper( name[i] ) )
                name[i] = tolower( name[i] );

    } else {
        /* Host name not found.  Use ascii representation of the address. */
        strncpy( name, ntop, namelen );
    }

    return name;
}

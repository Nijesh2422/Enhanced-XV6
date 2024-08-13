#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>

int main()
{
    int sockfds = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sockfds < 0)
    {
        printf("Error in Socket\n");
        exit(1);
    }
    struct sockaddr_in ServerAddress, ClientAddress;
    ServerAddress.sin_family = AF_INET;
    ServerAddress.sin_port = htons(5100);
    ServerAddress.sin_addr.s_addr = htonl(INADDR_ANY);
    int status = bind(sockfds, (struct sockaddr *)&ServerAddress, sizeof(ServerAddress));
    if (status == -1)
    {
        printf("Error in Bind\n");
        exit(1);
    }
    if (listen(sockfds, 6) == -1)
    {
        printf("Error in listen\n");
        exit(1);
    }
    while (1)
    {
        int ClientLength = sizeof(ClientAddress);
        bzero((char *)&ClientAddress, ClientLength);
        int TransSock = accept(sockfds, (struct sockaddr *)&ClientAddress, &ClientLength);
        if (TransSock < 0)
        {
            printf("Error in Accept\n");
            exit(1);
        }
        char Buffer[4096];
        bzero(Buffer, 4096);
        int count = recv(TransSock, Buffer, sizeof(Buffer), 0);
        if (count == -1)
        {
            printf("Error in Sending\n");
            exit(1);
        }
        printf("%s\n", Buffer);
        strcpy(Buffer, "Hi This is Avada Kedavra");
        int cunt = send(TransSock, Buffer, 4096, 0);
        if (cunt == -1)
        {
            printf("Error in Sending\n");
            exit(1);
        }
        int TranssockClosure = close(TransSock);
        if (TranssockClosure == -1)
        {
            printf("Closing Socket Failed");
            exit(1);
        }
    }
    int closure = close(sockfds);
    if (closure == -1)
    {
        printf("Closing Socket Failed");
        exit(1);
    }
}
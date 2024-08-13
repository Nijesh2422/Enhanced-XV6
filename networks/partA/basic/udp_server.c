#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>

int main()
{
    int sockfds = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sockfds < 0)
    {
        printf("Socket Creation Failed\n");
        exit(1);
    }
    struct sockaddr_in ServerAddressPort, ClientAddressPort;
    ServerAddressPort.sin_port = htons(5100);
    ServerAddressPort.sin_family = AF_INET;
    ServerAddressPort.sin_addr.s_addr = htonl(INADDR_ANY);

    if (bind(sockfds, (struct sockaddr *)&ServerAddressPort, sizeof(ServerAddressPort)) < 0)
    {
        printf("Binding Failed\n");
        exit(1);
    }

    char Buffer[4096];
    while (1)
    {
        bzero(Buffer, 4096);
        int ClientLength = sizeof(ClientAddressPort);
        bzero((char *)&ClientAddressPort, ClientLength);
        if (recvfrom(sockfds, Buffer, 4096, 0, (struct sockaddr *)&ClientAddressPort, &ClientLength) == -1)
        {
            printf("Recieving Failed\n");
            exit(1);
        }
        printf("%s\n", Buffer);
        bzero(Buffer, 4096);
        strcpy(Buffer, "Hi this is Avada Kedavra");
        if (sendto(sockfds, Buffer, sizeof(Buffer), 0, (struct sockaddr *)&ClientAddressPort, ClientLength) == -1)
        {
            printf("Sending Failed\n");
            exit(1);
        }
    }

    if (close(sockfds) == -1)
    {
        printf("Closing Socket Failed\n");
        exit(1);
    }
}
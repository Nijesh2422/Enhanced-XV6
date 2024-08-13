#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>

int main()
{
    int sockfdc = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sockfdc < 0)
    {
        printf("Socket Creation Failed\n");
        exit(1);
    }
    
    struct sockaddr_in ServerAddressPort;
    ServerAddressPort.sin_port = htons(5100);
    ServerAddressPort.sin_family = AF_INET;
    ServerAddressPort.sin_addr.s_addr = inet_addr("127.0.0.1");

    char Buffer[4096] = "Hi This is Expelliarmus";

    int Buflen = strlen(Buffer);
    int serverLength = sizeof(ServerAddressPort);
    if (sendto(sockfdc, Buffer, sizeof(Buffer), 0, (struct sockaddr *)&ServerAddressPort, serverLength) == -1)
    {
        printf("Sending Failed\n");
        exit(1);
    }
    bzero(Buffer, 4096);
    if (recvfrom(sockfdc, Buffer, 4096, 0, (struct sockaddr *)&ServerAddressPort, &serverLength) == -1)
    {
        printf("Recieving Failed\n");
        exit(1);
    }
    printf("%s\n", Buffer);
    if (close(sockfdc) == -1)
    {
        printf("Closing Socket Failed\n");
        exit(1);
    }
}
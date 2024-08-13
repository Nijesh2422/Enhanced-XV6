#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>

int main()
{
    int sockfdc = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sockfdc < 0)
    {
        printf("Error in Socket\n");
        exit(1);
    }
    struct sockaddr_in ServerAddressPort;
    ServerAddressPort.sin_family = AF_INET;
    ServerAddressPort.sin_port = htons(5100);
    ServerAddressPort.sin_addr.s_addr = inet_addr("127.0.0.1");
    if (connect(sockfdc, (struct sockaddr *)&ServerAddressPort, sizeof(ServerAddressPort)) == -1)
    {
        printf("Error in Connect\n");
        exit(1);
    }
    char Buffer[4096] = "Hi This is Expelliarmus";
    int cunt = send(sockfdc,Buffer,4096,0);
    if(cunt == -1)
    {
        printf("Error in Sending\n");
        exit(1);
    }
    bzero(Buffer, 4096);
    int count = recv(sockfdc, Buffer, sizeof(Buffer), 0);
    if (count == -1)
    {
        printf("Error in Recieving\n");
        exit(1);
    }
    printf("%s\n",Buffer);
    int closure = close(sockfdc);
    if (closure == -1)
    {
        printf("Closing Socket Failed");
        exit(1);
    }
}
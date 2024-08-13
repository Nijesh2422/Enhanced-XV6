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
    struct sockaddr_in ServerAddressPortA, ServerAddressPortB, ClientAddressPortA, ClientAddressPortB;
    ServerAddressPortA.sin_port = htons(5100);
    ServerAddressPortA.sin_family = AF_INET;
    ServerAddressPortA.sin_addr.s_addr = htonl(INADDR_ANY);
    if (bind(sockfds, (struct sockaddr *)&ServerAddressPortA, sizeof(ServerAddressPortA)) < 0)
    {
        printf("Binding Failed\n");
        exit(1);
    }
    int sockfdsB = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sockfdsB < 0)
    {
        printf("Socket Creation Failed\n");
        exit(1);
    }
    ServerAddressPortB.sin_port = htons(5566);
    ServerAddressPortB.sin_family = AF_INET;
    ServerAddressPortB.sin_addr.s_addr = htonl(INADDR_ANY);
    if (bind(sockfdsB, (struct sockaddr *)&ServerAddressPortB, sizeof(ServerAddressPortB)) < 0)
    {
        printf("Binding Failed\n");
        exit(1);
    }
    while (1)
    {
        char BufferA[10];
        bzero(BufferA, 10);
        int ClientLengthA = sizeof(ClientAddressPortA);
        if (recvfrom(sockfds, BufferA, 10, 0, (struct sockaddr *)&ClientAddressPortA, &ClientLengthA) == -1)
        {
            printf("Recieving Failed\n");
            exit(1);
        }
        char BufferB[10];
        bzero(BufferB, 10);
        int ClientLengthB = sizeof(ClientAddressPortB);
        if (recvfrom(sockfdsB, BufferB, 10, 0, (struct sockaddr *)&ClientAddressPortB, &ClientLengthB) == -1)
        {
            printf("Recieving Failed\n");
            exit(1);
        }
        int ValA = atoi(BufferA);
        int ValB = atoi(BufferB);
        if (ValA == ValB)
        {
            strcpy(BufferA, "Draw\n");
            if (sendto(sockfds, BufferA, sizeof(BufferA), 0, (struct sockaddr *)&ClientAddressPortA, ClientLengthA) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
            strcpy(BufferB, "Draw\n");
            if (sendto(sockfdsB, BufferB, sizeof(BufferB), 0, (struct sockaddr *)&ClientAddressPortB, ClientLengthB) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
        }
        else if (ValA == 1 + ValB)
        {
            strcpy(BufferA, "Lost\n");
            if (sendto(sockfds, BufferA, sizeof(BufferA), 0, (struct sockaddr *)&ClientAddressPortA, ClientLengthA) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
            strcpy(BufferB, "Win\n");
            if (sendto(sockfdsB, BufferB, sizeof(BufferB), 0, (struct sockaddr *)&ClientAddressPortB, ClientLengthB) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
        }
        else if (ValB == ValA + 1)
        {
            strcpy(BufferA, "Win\n");
            if (sendto(sockfds, BufferA, sizeof(BufferA), 0, (struct sockaddr *)&ClientAddressPortA, ClientLengthA) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
            strcpy(BufferB, "Lost\n");
            if (sendto(sockfdsB, BufferB, sizeof(BufferB), 0, (struct sockaddr *)&ClientAddressPortB, ClientLengthB) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
        }
        else if (ValA == ValB + 2)
        {
            strcpy(BufferA, "Win\n");
            if (sendto(sockfds, BufferA, sizeof(BufferA), 0, (struct sockaddr *)&ClientAddressPortA, ClientLengthA) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
            strcpy(BufferB, "Lost\n");
            if (sendto(sockfdsB, BufferB, sizeof(BufferB), 0, (struct sockaddr *)&ClientAddressPortB, ClientLengthB) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
        }
        else if (ValB == ValA + 2)
        {
            strcpy(BufferA, "Lost\n");
            if (sendto(sockfds, BufferA, sizeof(BufferA), 0, (struct sockaddr *)&ClientAddressPortA, ClientLengthA) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
            strcpy(BufferB, "Win\n");
            if (sendto(sockfdsB, BufferB, sizeof(BufferB), 0, (struct sockaddr *)&ClientAddressPortB, ClientLengthB) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
        }
        bzero(BufferA, 10);
        if (recvfrom(sockfds, BufferA, 10, 0, (struct sockaddr *)&ClientAddressPortA, &ClientLengthA) == -1)
        {
            printf("Recieving Failed\n");
            exit(1);
        }
        bzero(BufferB, 10);
        if (recvfrom(sockfdsB, BufferB, 10, 0, (struct sockaddr *)&ClientAddressPortB, &ClientLengthB) == -1)
        {
            printf("Recieving Failed\n");
            exit(1);
        }
        if (!strcmp(BufferA, "n") || !strcmp(BufferB, "n"))
        {
            strcpy(BufferA, "Close\n");
            if (sendto(sockfds, BufferA, sizeof(BufferA), 0, (struct sockaddr *)&ClientAddressPortA, ClientLengthA) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
            strcpy(BufferB, "Close\n");
            if (sendto(sockfdsB, BufferB, sizeof(BufferB), 0, (struct sockaddr *)&ClientAddressPortB, ClientLengthB) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
            break;
        }
        else
        {
            strcpy(BufferA, "Start");
            if (sendto(sockfds, BufferA, sizeof(BufferA), 0, (struct sockaddr *)&ClientAddressPortA, ClientLengthA) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
            strcpy(BufferB, "Start");
            if (sendto(sockfdsB, BufferB, sizeof(BufferB), 0, (struct sockaddr *)&ClientAddressPortB, ClientLengthB) == -1)
            {
                printf("Sending Failed\n");
                exit(1);
            }
        }
    }
    if (close(sockfds) == -1)
    {
        printf("Closing Socket Failed\n");
        exit(1);
    }
    if (close(sockfdsB) == -1)
    {
        printf("Closing Socket Failed\n");
        exit(1);
    }
}
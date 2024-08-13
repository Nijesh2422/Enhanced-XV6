Data Sequencing:

In both TCP and my implementation of TCP each data segment is assigned a unique sequence number and this sequence number is used for the ordering of the segments. If the reciever recieves the segments out of order the sequence numbers will be useful in that case to reorder the data in the correct format. In in both the implementations if any segments are missing, the acknowledgement for that data segment is not sent by the reciever this triggers the sender to resend that particular data segment.

Retransmissions:

In Traditional TCP:
When a sender (client or server) sends data segments to a receiver, it starts a timer for each segment. The timer is used to keep track of how long it takes for an acknowledgment (ACK) to be received from the receiver. If the sender doesn't receive an ACK within a certain timeout period, it assumes that the segment was lost or corrupted during transmission. In this case, the sender retransmits the segment. Retransmissions continue until the sender receives an ACK for the data or reaches a predefined maximum number of retransmission attempts (usually resulting in a connection termination).

In my implementation of TCP:
Sender saves the time a particular segment has been sent and it waits for ACKS. Once it gets the ACK it checks if the time it recieved is within timeout period, if it isn't then it assumes that the segment has been corrupted mark that the particular segment is still not sent and if the time is within the timeout period then the sender marks that the segment has been sent and does not send it again. Retransmissions continue until all the segments are marked sent and this is kept track using the fact that both sender and reciever know the total number of segments that are being sent. 

Flow Control:
Since the sender is also communicating the number of chunks of data that are being sent, it can wait for the acknowledgement of the "number of chunks." In the acknowledgement, the receiver can send its initial Receiver's Window, indicating how much data the receiver can initially accept and store. If this initial Receiver's Window is smaller than a single data segment, the sender will resize the data to fit within the Receiver's Window and then send the data segment. After sending the data segment, the sender calculates the sender's window(the amount of unacknowledged data it can send before it needs to wait for acknowledgments) every time it receives an acknowledgment. Subsequent acknowledgments will also contain the updated Receiver's Window, allowing the sender to adjust the data transmission based on both the Sender's and Receiver's Windows to control the flow.
